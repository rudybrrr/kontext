import Foundation
@testable import Capture

enum EvalExtractionPipeline: String, Sendable {
    case deterministic
    case model
    case merged
}

@MainActor
struct EvalRunner {
    let bundle: Bundle
    let deterministic = DeterministicActionExtractor()
    let model = FoundationModelActionExtractor()
    let merged = ResilientActionExtractionService()
    let embedder = NaturalLanguageEmbeddingService()
    let merger = ActionCandidateMerger()

    func run() async throws -> EvalSuiteReport {
        let dataset = try EvalFixtureLoader.loadDataset(bundle: bundle)
        let searchFile = try EvalFixtureLoader.loadSearchQueries(bundle: bundle)

        var actionResults: [EvalActionPipelineResult] = []
        actionResults.append(await evaluateActions(dataset: dataset, pipeline: .deterministic))
        if FoundationModelActionExtractor.isAvailable {
            actionResults.append(await evaluateActions(dataset: dataset, pipeline: .model))
            actionResults.append(await evaluateActions(dataset: dataset, pipeline: .merged))
        }

        var searchResults: [EvalSearchPipelineResult] = []
        for mode in [EvalSearchMode.lexical, .semantic, .blend] {
            searchResults.append(await evaluateSearch(dataset: dataset, queries: searchFile.queries, mode: mode))
        }

        return EvalSuiteReport(
            generatedAtISO: ISO8601DateFormatter().string(from: Date()),
            deviceModel: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "physical-device",
            timezone: dataset.timezone,
            actionPipelines: actionResults,
            searchPipelines: searchResults,
            targets: EvalTargets(
                precision: 0.85,
                recall: 0.70,
                exactDateAccuracy: 0.85,
                recallAt5: 0.85,
                extractionP95Ms: 3000
            )
        )
    }

    private func evaluateActions(dataset: EvalDataset, pipeline: EvalExtractionPipeline) async -> EvalActionPipelineResult {
        var overallTP = 0
        var overallExpected = 0
        var overallPredicted = 0
        var perKindTP: [String: Int] = [:]
        var perKindExpected: [String: Int] = [:]
        var perKindPredicted: [String: Int] = [:]
        var exactDateMatches = 0
        var fifteenMinuteMatches = 0
        var datePairs = 0
        var allDayPairs = 0
        var allDayErrors = 0
        var negativeCount = 0
        var negativeFP = 0
        var latencySamples: [Double] = []
        let clock = ContinuousClock()

        for capture in dataset.captures {
            let text = EvalFixtureText.extractionText(for: capture)
            let reference = EvalDateParsing.referenceDate(for: capture)
            let start = clock.now
            let predicted = await predict(pipeline: pipeline, text: text, referenceDate: reference)
            let elapsed = start.duration(to: clock.now)
            latencySamples.append(durationMs(elapsed))

            let predictedActions = predicted.map(EvalPredictedAction.init)
            if capture.negative {
                negativeCount += 1
                if !predictedActions.isEmpty { negativeFP += 1 }
                continue
            }

            let pairs = EvalActionMatcher.greedyMatch(expected: capture.expectedActions, predicted: predictedActions)
            overallTP += pairs.count
            overallExpected += capture.expectedActions.count
            overallPredicted += predictedActions.count

            for pair in pairs {
                if EvalActionMatcher.isExactDateMatch(expected: pair.0, predicted: pair.1) { exactDateMatches += 1 }
                if EvalActionMatcher.isFifteenMinuteDateMatch(expected: pair.0, predicted: pair.1) { fifteenMinuteMatches += 1 }
                datePairs += 1
                if pair.0.isAllDay || pair.1.isAllDay {
                    allDayPairs += 1
                    if pair.0.isAllDay != pair.1.isAllDay { allDayErrors += 1 }
                }
            }

            for expected in capture.expectedActions {
                perKindExpected[expected.kind, default: 0] += 1
            }
            for predictedAction in predictedActions {
                perKindPredicted[predictedAction.kind.rawValue, default: 0] += 1
            }
            for pair in pairs {
                perKindTP[pair.0.kind, default: 0] += 1
            }
        }

        let kinds = Set(perKindExpected.keys).union(perKindPredicted.keys)
        var perKind: [String: EvalPRMetrics] = [:]
        for kind in kinds {
            let tp = perKindTP[kind, default: 0]
            perKind[kind] = EvalMetricsCalculator.prMetrics(
                expectedCount: perKindExpected[kind, default: 0],
                predictedCount: perKindPredicted[kind, default: 0],
                truePositives: tp
            )
        }

        return EvalActionPipelineResult(
            pipeline: pipeline.rawValue,
            overall: EvalMetricsCalculator.prMetrics(
                expectedCount: overallExpected,
                predictedCount: overallPredicted,
                truePositives: overallTP
            ),
            perKind: perKind,
            exactDateAccuracy: datePairs == 0 ? 1 : Double(exactDateMatches) / Double(datePairs),
            fifteenMinuteDateAccuracy: datePairs == 0 ? 1 : Double(fifteenMinuteMatches) / Double(datePairs),
            allDayErrorRate: allDayPairs == 0 ? 0 : Double(allDayErrors) / Double(allDayPairs),
            negativeFalsePositiveRate: negativeCount == 0 ? 0 : Double(negativeFP) / Double(negativeCount),
            latencyMs: EvalMetricsCalculator.latencyStats(from: latencySamples)
        )
    }

    private func predict(pipeline: EvalExtractionPipeline, text: String, referenceDate: Date) async -> [ActionCandidate] {
        switch pipeline {
        case .deterministic:
            return (try? await deterministic.extractActions(from: text, referenceDate: referenceDate)) ?? []
        case .model:
            return (try? await model.extractActions(from: text, referenceDate: referenceDate)) ?? []
        case .merged:
            return (try? await merged.extractActions(from: text, referenceDate: referenceDate)) ?? []
        }
    }

    private func evaluateSearch(
        dataset: EvalDataset,
        queries: [EvalSearchQuery],
        mode: EvalSearchMode
    ) async -> EvalSearchPipelineResult {
        let idMap = Dictionary(uniqueKeysWithValues: dataset.captures.map { ($0.id, UUID()) })
        var documents: [SearchDocument] = []
        for capture in dataset.captures {
            guard let uuid = idMap[capture.id] else { continue }
            let text = EvalFixtureText.searchText(for: capture)
            let vector = await embedder.vector(for: text)
            documents.append(SearchDocument(id: uuid, text: text, createdAt: EvalDateParsing.referenceDate(for: capture), embedding: vector))
        }

        var r1 = 0.0
        var r5 = 0.0
        var r10 = 0.0
        var latency: [Double] = []
        let clock = ContinuousClock()

        for query in queries {
            let relevantUUIDs = Set(query.relevantCaptureIds.compactMap { idMap[$0] })
            let start = clock.now
            let queryVector = mode == .lexical ? nil : await embedder.vector(for: query.query)
            let ranked = EvalSearchRanker.rank(query: query.query, queryVector: queryVector, documents: documents, mode: mode)
            let elapsed = start.duration(to: clock.now)
            latency.append(durationMs(elapsed))

            let rankedIDs = ranked.map(\.id)
            r1 += EvalMetricsCalculator.recallAt(rankedIDs, relevant: relevantUUIDs, k: 1)
            r5 += EvalMetricsCalculator.recallAt(rankedIDs, relevant: relevantUUIDs, k: 5)
            r10 += EvalMetricsCalculator.recallAt(rankedIDs, relevant: relevantUUIDs, k: 10)
        }

        let count = Double(max(queries.count, 1))
        return EvalSearchPipelineResult(
            mode: mode.rawValue,
            recallAt1: r1 / count,
            recallAt5: r5 / count,
            recallAt10: r10 / count,
            latencyMs: EvalMetricsCalculator.latencyStats(from: latency)
        )
    }
}

private func durationMs(_ elapsed: Duration) -> Double {
    Double(elapsed.components.seconds) * 1000 + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000
}

enum EvalReportFormatter {
    static func markdownTable(for report: EvalSuiteReport) -> String {
        var lines: [String] = []
        lines.append("| Pipeline | Precision | Recall | Exact date | FP (neg) | p50 ms | p95 ms |")
        lines.append("|---|---:|---:|---:|---:|---:|---:|")
        for row in report.actionPipelines {
            lines.append(String(format: "| %@ | %.3f | %.3f | %.3f | %.3f | %.1f | %.1f |",
                                row.pipeline, row.overall.precision, row.overall.recall,
                                row.exactDateAccuracy, row.negativeFalsePositiveRate,
                                row.latencyMs.p50Ms, row.latencyMs.p95Ms))
        }
        lines.append("")
        lines.append("| Search | R@1 | R@5 | R@10 | p50 ms | p95 ms |")
        lines.append("|---|---:|---:|---:|---:|---:|")
        for row in report.searchPipelines {
            lines.append(String(format: "| %@ | %.3f | %.3f | %.3f | %.1f | %.1f |",
                                row.mode, row.recallAt1, row.recallAt5, row.recallAt10,
                                row.latencyMs.p50Ms, row.latencyMs.p95Ms))
        }
        return lines.joined(separator: "\n")
    }
}
