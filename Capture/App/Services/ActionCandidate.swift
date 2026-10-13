import Foundation

struct ActionCandidate: Sendable, Equatable {
    let kind: ProposedActionKind
    let title: String
    let start: Date?
    let end: Date?
    let isAllDay: Bool
    let due: Date?
    let location: String?
    let people: [String]
    let url: String?
    let sourceSpan: String?
    let confidence: Double

    func asProposedAction() -> ProposedAction {
        ProposedAction(
            kind: kind,
            title: title,
            start: start,
            end: end,
            isAllDay: isAllDay,
            due: due,
            location: location,
            people: people,
            url: url,
            sourceSpan: sourceSpan,
            confidence: confidence
        )
    }
}
