import EventKit
import Foundation

enum ProposedActionApprovalError: Error, Equatable {
    case accessDenied(ProposedActionKind)
}

@MainActor
struct ProposedActionApprovalService {
    let committer: ActionCommitting

    init(committer: ActionCommitting = EventKitActionCommitter()) {
        self.committer = committer
    }

    func dismiss(_ action: ProposedAction) {
        action.status = .dismissed
    }

    func retry(_ action: ProposedAction) {
        guard action.status == .failed else { return }
        action.status = .proposed
        action.ekIdentifier = nil
    }

    func markApproved(_ action: ProposedAction, ekIdentifier: String) {
        action.ekIdentifier = ekIdentifier
        action.status = .approved
    }

    func markFailed(_ action: ProposedAction) {
        action.status = .failed
    }

    func prefilledEvent(for action: ProposedAction) -> EKEvent {
        committer.makePrefilledEvent(from: action)
    }

    func ensureAccess(for kind: ProposedActionKind) async -> Result<Void, ProposedActionApprovalError> {
        switch kind {
        case .event:
            let access = await committer.requestEventsAccessIfNeeded()
            return access == .granted ? .success(()) : .failure(.accessDenied(.event))
        case .reminder, .followUp:
            let access = await committer.requestRemindersAccessIfNeeded()
            return access == .granted ? .success(()) : .failure(.accessDenied(kind))
        }
    }

    func saveReminder(
        action: ProposedAction,
        title: String,
        due: Date?
    ) throws -> String {
        let notes = [action.sourceSpan, action.people.isEmpty ? nil : action.people.joined(separator: ", ")]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        let identifier = try committer.saveReminder(
            title: title,
            notes: notes.nilIfEmpty,
            due: due ?? action.due,
            url: action.url
        )
        markApproved(action, ekIdentifier: identifier)
        return identifier
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
