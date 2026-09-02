import Foundation
import FoundationModels

enum OnDeviceModelStatus: Sendable {
    case available
    case unavailable(String)
}

enum FoundationModelEnrichmentError: Error {
    case unavailable
    case unsupportedLanguage
}

@Generable(description: "Structured metadata for one locally captured item")
private struct GeneratedEnrichment {
    @Guide(description: "A concise recognizable title")
    let title: String
    @Guide(description: "A one or two sentence factual summary")
    let summary: String
    @Guide(description: "Up to five short topic or entity tags")
    let tags: [String]
    @Guide(description: "An existing context name, or one conservative new context name")
    let contextName: String
    @Guide(description: "A short description if proposing a new context")
    let contextSummary: String
    @Guide(description: "Confidence from zero to one", .range(0...1))
    let confidence: Double
}

struct FoundationModelEnrichmentService: EnrichmentProviding {
    static var status: OnDeviceModelStatus {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return model.supportsLocale() ? .available : .unavailable("Current language is not supported")
        case .unavailable(.deviceNotEligible):
            return .unavailable("This device is not eligible")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable("Apple Intelligence is disabled")
        case .unavailable(.modelNotReady):
            return .unavailable("The on-device model is not ready")
        @unknown default:
            return .unavailable("The on-device model is unavailable")
        }
    }

    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult {
        let model = SystemLanguageModel.default
        guard model.availability == .available else { throw FoundationModelEnrichmentError.unavailable }
        guard model.supportsLocale() else { throw FoundationModelEnrichmentError.unsupportedLanguage }

        let existing = contexts.isEmpty
            ? "No contexts exist. Propose a new context only when highly confident; otherwise use Inbox."
            : contexts.map { "- \($0.name): \($0.summary ?? "")" }.joined(separator: "\n")
        let session = LanguageModelSession(
            model: model,
            instructions: "Organize a local capture. Prefer an existing context. Never propose actions, deletion, or external communication. Use Inbox when uncertain."
        )
        let response = try await session.respond(
            to: "Captured content:\n\(text)\n\nExisting contexts:\n\(existing)",
            generating: GeneratedEnrichment.self
        )
        let value = response.content
        let contextName = value.contextName.trimmingCharacters(in: .whitespacesAndNewlines)
        return EnrichmentResult(
            title: value.title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: value.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: Array(Set(value.tags.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted().prefix(5).map { $0 },
            suggestedContextName: contextName.isEmpty || contextName.caseInsensitiveCompare("Inbox") == .orderedSame ? nil : contextName,
            suggestedContextSummary: value.contextSummary.trimmingCharacters(in: .whitespacesAndNewlines),
            contextConfidence: min(1, max(0, value.confidence))
        )
    }
}
