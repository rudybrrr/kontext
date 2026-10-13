import Foundation

enum URLFollowUpProposalService {
    static func readFollowUpCandidate(for item: CaptureItem) -> ActionCandidate? {
        guard item.kind == .url, let urlString = item.sourceURL, !urlString.isEmpty else { return nil }
        let title = readTitle(for: item)
        return ActionCandidate(
            kind: .followUp,
            title: "Read \(title)",
            start: nil,
            end: nil,
            isAllDay: false,
            due: nil,
            location: nil,
            people: [],
            url: urlString,
            sourceSpan: urlString,
            confidence: 0.92
        )
    }

    static func readTitle(for item: CaptureItem) -> String {
        if let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        if let source = item.sourceURL, let host = URL(string: source)?.host(), !host.isEmpty {
            return host
        }
        return "this link"
    }

    static func alreadyProposedReadFollowUp(for item: CaptureItem, matching url: String) -> Bool {
        item.proposedActions.contains { action in
            action.kind == .followUp
                && action.url == url
                && action.title.hasPrefix("Read ")
                && action.status != .dismissed
        }
    }

    static func appendReadFollowUpIfNeeded(to candidates: inout [ActionCandidate], item: CaptureItem) {
        guard let candidate = readFollowUpCandidate(for: item) else { return }
        guard let url = candidate.url else { return }
        guard !alreadyProposedReadFollowUp(for: item, matching: url) else { return }
        guard !candidates.contains(where: { $0.kind == .followUp && $0.url == url && $0.title == candidate.title }) else { return }
        candidates.append(candidate)
    }
}
