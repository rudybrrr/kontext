import SwiftData
import XCTest
@testable import Capture

final class EnrichmentTests: XCTestCase {
    func testFallbackCreatesRecognizableMetadata() async throws {
        let result = try await FallbackEnrichmentService().enrich(
            text: "Swift actors improve browser networking. Swift concurrency keeps shared state safe.",
            contexts: []
        )

        XCTAssertEqual(result.title, "Swift actors improve browser networking")
        XCTAssertTrue(result.summary.contains("Swift actors"))
        XCTAssertTrue(result.tags.contains("swift"))
        XCTAssertNil(result.suggestedContextName)
    }

    func testUnavailablePrimaryUsesDeterministicFallback() async throws {
        let service = ResilientEnrichmentService(primary: ThrowingEnricher(), fallback: FallbackEnrichmentService())

        let result = try await service.enrich(text: "AVL tree rotations", contexts: [])

        XCTAssertEqual(result.title, "AVL tree rotations")
    }

    @MainActor
    func testCoordinatorFailurePreservesOriginalCapture() async throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let item = try CaptureStore(container: container).captureText("Original text that must survive")
        let coordinator = EnrichmentCoordinator(enricher: ThrowingEnricher(), embedder: NoEmbedding())

        await coordinator.process(item, contexts: [], modelContext: container.mainContext)

        let fetched = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<CaptureItem>()).first)
        XCTAssertEqual(fetched.rawText, "Original text that must survive")
        XCTAssertEqual(fetched.enrichmentState, .failed)
    }

    @MainActor
    func testCoordinatorCompletesAndAssignsExistingSuggestedContext() async throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let store = CaptureStore(container: container)
        let item = try store.captureText("Arc sidebar reference")
        let context = try store.createContext(name: "mybrowser", summary: "Browser work")
        let result = EnrichmentResult(
            title: "Arc sidebar",
            summary: "A vertical tabs reference.",
            tags: ["browser", "sidebar"],
            suggestedContextName: "mybrowser",
            suggestedContextSummary: nil,
            contextConfidence: 0.92
        )
        let coordinator = EnrichmentCoordinator(enricher: FixedEnricher(result: result), embedder: FixedEmbedding())

        await coordinator.process(item, contexts: [context], modelContext: container.mainContext)

        XCTAssertEqual(item.title, "Arc sidebar")
        XCTAssertEqual(item.enrichmentState, .completed)
        XCTAssertEqual(item.context?.id, context.id)
        XCTAssertNotNil(item.embeddingData)
    }

    @MainActor
    func testCoordinatorReusesPersistedInboxWhenContextSnapshotIsStale() async throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let store = CaptureStore(container: container)
        let first = try store.captureText("First uncertain capture")
        let second = try store.captureText("Second uncertain capture")
        let result = EnrichmentResult(
            title: "Uncertain",
            summary: "No confident context.",
            tags: [],
            suggestedContextName: nil,
            suggestedContextSummary: nil,
            contextConfidence: 0
        )
        let coordinator = EnrichmentCoordinator(enricher: FixedEnricher(result: result), embedder: NoEmbedding())

        await coordinator.process(first, contexts: [], modelContext: container.mainContext)
        await coordinator.process(second, contexts: [], modelContext: container.mainContext)

        let inboxCount = try container.mainContext.fetch(FetchDescriptor<CaptureContext>()).filter { $0.name == "Inbox" }.count
        XCTAssertEqual(inboxCount, 1)
        XCTAssertEqual(first.context?.id, second.context?.id)
    }
}

private enum TestEnrichmentError: Error { case unavailable }

private struct ThrowingEnricher: EnrichmentProviding {
    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult {
        throw TestEnrichmentError.unavailable
    }
}

private struct FixedEnricher: EnrichmentProviding {
    let result: EnrichmentResult
    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult { result }
}

private struct NoEmbedding: EmbeddingProviding {
    func vector(for text: String) async -> [Double]? { nil }
}

private struct FixedEmbedding: EmbeddingProviding {
    func vector(for text: String) async -> [Double]? { [1, 0] }
}
