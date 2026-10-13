import SwiftData
import XCTest
@testable import Capture

final class URLFollowUpProposalTests: XCTestCase {
    func testProposesReadFollowUpForURLCapture() {
        let item = CaptureItem(kind: .url, sourceURL: "https://example.com/article")
        item.title = "Example Article"

        let candidate = URLFollowUpProposalService.readFollowUpCandidate(for: item)

        XCTAssertEqual(candidate?.kind, .followUp)
        XCTAssertEqual(candidate?.title, "Read Example Article")
        XCTAssertEqual(candidate?.url, "https://example.com/article")
        XCTAssertNil(candidate?.due)
    }

    func testAppendReadFollowUpAddsCandidateOnce() {
        let item = CaptureItem(kind: .url, sourceURL: "https://example.com")
        item.title = "Example"
        var candidates: [ActionCandidate] = []

        URLFollowUpProposalService.appendReadFollowUpIfNeeded(to: &candidates, item: item)
        URLFollowUpProposalService.appendReadFollowUpIfNeeded(to: &candidates, item: item)

        XCTAssertEqual(candidates.count, 1)
    }
}

@MainActor
final class RemindMeIntentTests: XCTestCase {
    func testConvertsIntentFlagIntoProposedFollowUp() throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let item = try CaptureStore(container: container).captureURL(
            URL(string: "https://news.example.com/story")!,
            remindMeIntent: true
        )
        XCTAssertTrue(item.remindMeIntent)

        try RemindMeIntentService().applyPendingIntents(modelContext: container.mainContext)

        XCTAssertFalse(item.remindMeIntent)
        XCTAssertEqual(item.proposedActions.count, 1)
        XCTAssertEqual(item.proposedActions.first?.kind, .followUp)
        XCTAssertEqual(item.proposedActions.first?.title, "Read news.example.com")
    }
}

final class HTMLTextExtractorTests: XCTestCase {
    func testExtractsReadableBodyText() {
        let html = """
        <html><head><title>T</title><style>body{color:red}</style></head>
        <body><script>ignore()</script><p>Hello <b>world</b>.</p></body></html>
        """

        let text = HTMLTextExtractor.extractBodyText(from: html)

        XCTAssertTrue(text.contains("Hello world."))
        XCTAssertFalse(text.contains("ignore"))
    }

    func testRespectsMaximumLength() {
        let body = String(repeating: "word ", count: 20_000)
        let html = "<html><body>\(body)</body></html>"
        let text = HTMLTextExtractor.extractBodyText(from: html)
        XCTAssertLessThanOrEqual(text.count, HTMLTextExtractor.maxCharacterCount)
    }
}

@MainActor
final class CaptureBackgroundDrainerTests: XCTestCase {
    func testFakeSchedulerRegistersAndSchedules() async {
        let scheduler = FakeCaptureBackgroundScheduler()
        var ran = false
        scheduler.register {
            ran = true
        }
        scheduler.scheduleProcessing(earliestBeginDate: Date(timeIntervalSince1970: 1))

        XCTAssertEqual(scheduler.registrationCount, 1)
        XCTAssertEqual(scheduler.scheduledDates.count, 1)
        await scheduler.runProcessing()
        XCTAssertTrue(ran)
    }

    func testDrainerProcessesPendingCapture() async throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let item = try CaptureStore(container: container).captureText("Background drain item")
        XCTAssertEqual(item.enrichmentState, .pending)

        let result = EnrichmentResult(
            title: "Background drain item",
            summary: "Summary",
            tags: [],
            suggestedContextName: nil,
            suggestedContextSummary: nil,
            contextConfidence: 0
        )
        let coordinator = EnrichmentCoordinator(
            enricher: FixedWeek3Enricher(result: result),
            embedder: NoWeek3Embedding(),
            webpageTextFetcher: WebpageTextFetcher()
        )
        let drainer = CaptureBackgroundDrainer(coordinator: coordinator)

        try await drainer.drain(modelContext: container.mainContext)

        XCTAssertEqual(item.enrichmentState, .completed)
        XCTAssertEqual(item.title, "Background drain item")
    }
}

private struct FixedWeek3Enricher: EnrichmentProviding {
    let result: EnrichmentResult
    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult { result }
}

private struct NoWeek3Embedding: EmbeddingProviding {
    func vector(for text: String) async -> [Double]? { nil }
}
