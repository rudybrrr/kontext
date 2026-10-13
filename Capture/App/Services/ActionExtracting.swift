import Foundation

protocol ActionExtracting: Sendable {
    func extractActions(from text: String, referenceDate: Date) async throws -> [ActionCandidate]
}

struct ResilientActionExtractionService: ActionExtracting {
    private let deterministic: any ActionExtracting
    private let model: any ActionExtracting
    private let merger: ActionCandidateMerger

    init(
        deterministic: any ActionExtracting = DeterministicActionExtractor(),
        model: any ActionExtracting = FoundationModelActionExtractor(),
        merger: ActionCandidateMerger = ActionCandidateMerger()
    ) {
        self.deterministic = deterministic
        self.model = model
        self.merger = merger
    }

    func extractActions(from text: String, referenceDate: Date) async throws -> [ActionCandidate] {
        let baseline = try await deterministic.extractActions(from: text, referenceDate: referenceDate)
        guard FoundationModelActionExtractor.isAvailable else {
            return merger.merge(
                sourceText: text,
                referenceDate: referenceDate,
                deterministic: baseline,
                model: [],
                modelExtractionAvailable: false
            )
        }
        do {
            let proposed = try await model.extractActions(from: text, referenceDate: referenceDate)
            return merger.merge(
                sourceText: text,
                referenceDate: referenceDate,
                deterministic: baseline,
                model: proposed,
                modelExtractionAvailable: true
            )
        } catch {
            return merger.merge(
                sourceText: text,
                referenceDate: referenceDate,
                deterministic: baseline,
                model: [],
                modelExtractionAvailable: false
            )
        }
    }
}
