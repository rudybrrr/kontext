import XCTest
@testable import Capture

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
