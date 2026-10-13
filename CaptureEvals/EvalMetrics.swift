import Foundation

struct EvalActionPipelineResult: Codable, Sendable {
    let pipeline: String
    let overall: EvalPRMetrics
    let perKind: [String: EvalPRMetrics]
    let exactDateAccuracy: Double
    let fifteenMinuteDateAccuracy: Double
    let allDayErrorRate: Double
    let negativeFalsePositiveRate: Double
    let latencyMs: EvalLatencyStats
}

struct EvalPRMetrics: Codable, Sendable {
    let precision: Double
    let recall: Double
    let truePositives: Int
    let falsePositives: Int
    let falseNegatives: Int
}

struct EvalLatencyStats: Codable, Sendable {
    let p50Ms: Double
    let p95Ms: Double
    let sampleCount: Int
}

struct EvalSearchPipelineResult: Codable, Sendable {
    let mode: String
    let recallAt1: Double
    let recallAt5: Double
    let recallAt10: Double
    let latencyMs: EvalLatencyStats
}

struct EvalSuiteReport: Codable, Sendable {
    let generatedAtISO: String
    let deviceModel: String
    let timezone: String
    let actionPipelines: [EvalActionPipelineResult]
    let searchPipelines: [EvalSearchPipelineResult]
    let targets: EvalTargets
}

struct EvalTargets: Codable, Sendable {
    let precision: Double
    let recall: Double
    let exactDateAccuracy: Double
    let recallAt5: Double
    let extractionP95Ms: Double
}

enum EvalMetricsCalculator {
    static func prMetrics(
        expectedCount: Int,
        predictedCount: Int,
        truePositives: Int
    ) -> EvalPRMetrics {
        let fp = max(0, predictedCount - truePositives)
        let fn = max(0, expectedCount - truePositives)
        let precision = predictedCount == 0 ? (expectedCount == 0 ? 1 : 0) : Double(truePositives) / Double(predictedCount)
        let recall = expectedCount == 0 ? 1 : Double(truePositives) / Double(expectedCount)
        return EvalPRMetrics(precision: precision, recall: recall, truePositives: truePositives, falsePositives: fp, falseNegatives: fn)
    }

    static func latencyStats(from samplesMs: [Double]) -> EvalLatencyStats {
        guard !samplesMs.isEmpty else { return EvalLatencyStats(p50Ms: 0, p95Ms: 0, sampleCount: 0) }
        let sorted = samplesMs.sorted()
        let p50 = percentile(sorted, 0.5)
        let p95 = percentile(sorted, 0.95)
        return EvalLatencyStats(p50Ms: p50, p95Ms: p95, sampleCount: sorted.count)
    }

    static func recallAt(_ rankedIDs: [UUID], relevant: Set<UUID>, k: Int) -> Double {
        guard !relevant.isEmpty else { return 1 }
        let top = Set(rankedIDs.prefix(k))
        return Double(top.intersection(relevant).count) / Double(relevant.count)
    }

    private static func percentile(_ sorted: [Double], _ p: Double) -> Double {
        let index = Int((Double(sorted.count - 1) * p).rounded())
        return sorted[max(0, min(sorted.count - 1, index))]
    }
}
