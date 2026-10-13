import SwiftData
import XCTest
@testable import Capture

private struct EvalFixedEnricher: EnrichmentProviding {
    let result: EnrichmentResult
    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult { result }
}

private struct EvalNoEmbedding: EmbeddingProviding {
    func vector(for text: String) async -> [Double]? { nil }
}

@MainActor
final class CaptureEvalsTests: XCTestCase {
    func testCaptureEvalSuite() async throws {
        let bundle = Bundle(for: CaptureEvalsTests.self)
        let report = try await EvalRunner(bundle: bundle).run()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)

        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("capture-evals-results.json")
        try data.write(to: outputURL)

        let attachment = XCTAttachment(contentsOfFile: outputURL)
        attachment.name = "capture-evals-results.json"
        attachment.lifetime = .keepAlways
        add(attachment)

        let markdown = EvalReportFormatter.markdownTable(for: report)
        print("\n### Capture eval results\n\n\(markdown)\n")

        XCTAssertFalse(report.actionPipelines.isEmpty)
        XCTAssertEqual(report.searchPipelines.count, 3)
    }

    func testBackgroundSchedulerRegistersAndDrainsPendingCapture() async throws {
        let scheduler = FakeCaptureBackgroundScheduler()
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let item = try CaptureStore(container: container).captureText("BG eval pending capture")
        let result = EnrichmentResult(
            title: "BG eval pending capture",
            summary: "Eval",
            tags: [],
            suggestedContextName: nil,
            suggestedContextSummary: nil,
            contextConfidence: 0
        )
        let coordinator = EnrichmentCoordinator(
            enricher: EvalFixedEnricher(result: result),
            embedder: EvalNoEmbedding()
        )
        var drained = false
        scheduler.register {
            let drainer = CaptureBackgroundDrainer(coordinator: coordinator)
            try? await drainer.drain(modelContext: container.mainContext)
            drained = true
        }
        scheduler.scheduleProcessing(earliestBeginDate: .now)
        await scheduler.runProcessing()
        XCTAssertTrue(drained)
        XCTAssertEqual(item.enrichmentState, .completed)
    }

    func testModelOnlyPipelineSkippedWhenUnavailable() async throws {
        guard !FoundationModelActionExtractor.isAvailable else {
            throw XCTSkip("Model is available; covered by full suite.")
        }
        let bundle = Bundle(for: CaptureEvalsTests.self)
        let report = try await EvalRunner(bundle: bundle).run()
        XCTAssertEqual(report.actionPipelines.count, 1)
        XCTAssertEqual(report.actionPipelines.first?.pipeline, EvalExtractionPipeline.deterministic.rawValue)
    }
}
