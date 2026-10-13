import SwiftData
import XCTest
@testable import Capture

final class ActionExtractionTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    func testDeterministicExtractorFindsRelativeFriday() async throws {
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 10, day: 9, hour: 9)))
        let results = try await DeterministicActionExtractor().extractActions(
            from: "Coffee next Fri at 10am",
            referenceDate: reference
        )

        XCTAssertEqual(results.count, 1)
        let event = try XCTUnwrap(results.first)
        XCTAssertEqual(event.kind, .event)
        XCTAssertEqual(calendar.component(.weekday, from: event.start!), 6)
        XCTAssertEqual(calendar.component(.hour, from: event.start!), 10)
    }

    func testDeterministicExtractorFindsAfternoonRange() async throws {
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 10, day: 9, hour: 9)))
        let results = try await DeterministicActionExtractor().extractActions(
            from: "Team sync 3-5pm tomorrow",
            referenceDate: reference
        )

        XCTAssertEqual(results.count, 1)
        let event = try XCTUnwrap(results.first)
        XCTAssertEqual(event.kind, .event)
        XCTAssertNotNil(event.start)
        XCTAssertNotNil(event.end)
        XCTAssertGreaterThan(event.end!, event.start!)
    }

    func testDeterministicExtractorFindsDayMonthDate() async throws {
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 10, day: 1)))
        let results = try await DeterministicActionExtractor().extractActions(
            from: "Dentist on 13/10/2026 at 15:00",
            referenceDate: reference
        )

        XCTAssertEqual(results.count, 1)
        let event = try XCTUnwrap(results.first)
        let start = try XCTUnwrap(event.start)
        XCTAssertEqual(calendar.component(.day, from: start), 13)
        XCTAssertEqual(calendar.component(.month, from: start), 10)
        XCTAssertEqual(calendar.component(.year, from: start), 2026)
    }

    func testDeterministicExtractorReturnsNoActionsForPlainNote() async throws {
        let reference = Date()
        let results = try await DeterministicActionExtractor().extractActions(
            from: "Swift actors improve shared-state safety in concurrent code.",
            referenceDate: reference
        )
        XCTAssertTrue(results.isEmpty)
    }

    func testMergerDropsLowConfidenceModelCandidates() {
        let merger = ActionCandidateMerger()
        let reference = Date()
        let deterministic: [ActionCandidate] = []
        let model = [
            ActionCandidate(
                kind: .event,
                title: "Low confidence meeting",
                start: reference,
                end: nil,
                isAllDay: false,
                due: nil,
                location: nil,
                people: [],
                url: nil,
                sourceSpan: "tomorrow at 3pm",
                confidence: 0.4
            )
        ]

        let merged = merger.merge(
            sourceText: "Low confidence meeting tomorrow at 3pm",
            referenceDate: reference,
            deterministic: deterministic,
            model: model,
            modelExtractionAvailable: true
        )

        XCTAssertTrue(merged.isEmpty)
    }

    func testMergerRequiresDetectorBackedModelDates() throws {
        let merger = ActionCandidateMerger()
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 10, day: 9, hour: 9)))
        let invented = try XCTUnwrap(calendar.date(from: DateComponents(year: 2031, month: 1, day: 1, hour: 9)))
        let model = [
            ActionCandidate(
                kind: .event,
                title: "Invented date",
                start: invented,
                end: nil,
                isAllDay: false,
                due: nil,
                location: nil,
                people: [],
                url: nil,
                sourceSpan: nil,
                confidence: 0.95
            )
        ]

        let merged = merger.merge(
            sourceText: "Coffee next Fri at 10am",
            referenceDate: reference,
            deterministic: [],
            model: model,
            modelExtractionAvailable: true
        )

        XCTAssertTrue(merged.isEmpty)
    }

    func testMergerDedupesDeterministicAndModelCandidates() async throws {
        let merger = ActionCandidateMerger()
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 10, day: 9, hour: 9)))
        let deterministic = try await DeterministicActionExtractor().extractActions(
            from: "Coffee next Fri at 10am",
            referenceDate: reference
        )
        let start = try XCTUnwrap(deterministic.first?.start)
        let model = [
            ActionCandidate(
                kind: .event,
                title: "Coffee next Fri at 10am",
                start: start,
                end: nil,
                isAllDay: false,
                due: nil,
                location: nil,
                people: [],
                url: nil,
                sourceSpan: "next Fri at 10am",
                confidence: 0.92
            )
        ]

        let merged = merger.merge(
            sourceText: "Coffee next Fri at 10am",
            referenceDate: reference,
            deterministic: deterministic,
            model: model,
            modelExtractionAvailable: true
        )

        XCTAssertEqual(merged.count, 1)
    }

    @MainActor
    func testProposedActionPersistsAndCascadeDeletesWithCapture() throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let store = CaptureStore(container: container)
        let item = try store.captureText("Lunch next Fri at noon")
        let action = ProposedAction(
            kind: .event,
            title: "Lunch",
            start: .now,
            confidence: 0.9
        )
        action.captureItem = item
        container.mainContext.insert(action)
        try container.mainContext.save()

        var actionFetch = FetchDescriptor<ProposedAction>()
        XCTAssertEqual(try container.mainContext.fetch(actionFetch).count, 1)

        container.mainContext.delete(item)
        try container.mainContext.save()

        actionFetch = FetchDescriptor<ProposedAction>()
        XCTAssertTrue(try container.mainContext.fetch(actionFetch).isEmpty)
    }

    @MainActor
    func testCoordinatorMarksPartialWhenActionExtractionFails() async throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let item = try CaptureStore(container: container).captureText("Meeting next Fri at 2pm")
        let result = EnrichmentResult(
            title: "Meeting",
            summary: "A meeting.",
            tags: ["meeting"],
            suggestedContextName: nil,
            suggestedContextSummary: nil,
            contextConfidence: 0
        )
        let coordinator = EnrichmentCoordinator(
            enricher: FixedEnricher(result: result),
            embedder: NoEmbedding(),
            actionExtractor: ThrowingActionExtractor()
        )

        await coordinator.process(item, contexts: [], modelContext: container.mainContext)

        XCTAssertEqual(item.enrichmentState, .partial)
        XCTAssertEqual(item.rawText, "Meeting next Fri at 2pm")
        XCTAssertTrue(item.proposedActions.isEmpty)
    }
}

private struct ThrowingActionExtractor: ActionExtracting {
    func extractActions(from text: String, referenceDate: Date) async throws -> [ActionCandidate] {
        throw TestActionExtractionError.failed
    }
}

private enum TestActionExtractionError: Error {
    case failed
}

private struct FixedEnricher: EnrichmentProviding {
    let result: EnrichmentResult
    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult { result }
}

private struct NoEmbedding: EmbeddingProviding {
    func vector(for text: String) async -> [Double]? { nil }
}
