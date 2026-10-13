import Foundation
import FoundationModels

@Generable(description: "One proposed action extracted from captured text")
private struct GeneratedActionCandidate {
    @Guide(description: "event, reminder, or followUp")
    let kind: String
    @Guide(description: "Short human-readable title")
    let title: String
    @Guide(description: "Event start time in ISO-8601 when applicable")
    let startISO8601: String?
    @Guide(description: "Event end time in ISO-8601 when applicable")
    let endISO8601: String?
    @Guide(description: "Whether the event is all-day")
    let isAllDay: Bool
    @Guide(description: "Reminder due time in ISO-8601 when applicable")
    let dueISO8601: String?
    @Guide(description: "Location name or address when present in the text")
    let location: String?
    @Guide(description: "People mentioned for the action")
    let people: [String]
    @Guide(description: "URL string when the action references a link")
    let url: String?
    @Guide(description: "Exact substring from the capture that supports this action")
    let sourceSpan: String?
    @Guide(description: "Confidence from zero to one", .range(0...1))
    let confidence: Double
}

@Generable(description: "Candidate actions the user may approve later")
private struct ActionCandidates {
    let candidates: [GeneratedActionCandidate]
}

struct FoundationModelActionExtractor: ActionExtracting {
    static var isAvailable: Bool {
        switch status {
        case .available: true
        case .unavailable: false
        }
    }

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

    func extractActions(from text: String, referenceDate: Date) async throws -> [ActionCandidate] {
        guard Self.isAvailable else { throw FoundationModelEnrichmentError.unavailable }
        let model = SystemLanguageModel.default
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let reference = formatter.string(from: referenceDate)
        let session = LanguageModelSession(
            model: model,
            instructions: """
            Propose zero or more calendar events, reminders, or follow-ups implied by the capture. \
            Never schedule or communicate externally. Only surface actions the user could approve later. \
            Use ISO-8601 timestamps. Prefer conservative titles and omit uncertain fields.
            """
        )
        let response = try await session.respond(
            to: "Reference date: \(reference)\n\nCaptured content:\n\(text)",
            generating: ActionCandidates.self
        )
        return response.content.candidates.compactMap { value in
            let kind = Self.kind(from: value.kind)
            let title = value.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let kind, !title.isEmpty else { return nil }
            return ActionCandidate(
                kind: kind,
                title: title,
                start: Self.date(from: value.startISO8601),
                end: Self.date(from: value.endISO8601),
                isAllDay: value.isAllDay,
                due: Self.date(from: value.dueISO8601),
                location: value.location?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                people: value.people.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
                url: value.url?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                sourceSpan: value.sourceSpan?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                confidence: min(1, max(0, value.confidence))
            )
        }
    }

    private static func kind(from raw: String) -> ProposedActionKind? {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "event": return .event
        case "reminder": return .reminder
        case "followup", "follow-up", "follow_up", "follow up": return .followUp
        default: return nil
        }
    }

    private static func date(from iso: String?) -> Date? {
        guard let iso, !iso.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = formatter.date(from: iso) { return value }
        formatter.formatOptions = [.withInternetDateTime]
        if let value = formatter.date(from: iso) { return value }
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: iso)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
