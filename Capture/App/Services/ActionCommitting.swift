import EventKit
import Foundation

enum ActionAccessResult: Sendable, Equatable {
    case granted
    case denied
}

enum ActionCommitError: Error, Equatable {
    case accessDenied
    case missingCalendar
    case saveFailed
}

protocol ActionCommitting: Sendable {
    func requestEventsAccessIfNeeded() async -> ActionAccessResult
    func requestRemindersAccessIfNeeded() async -> ActionAccessResult
    func makePrefilledEvent(from action: ProposedAction) -> EKEvent
    func saveReminder(title: String, notes: String?, due: Date?, url: String?) throws -> String
}

struct EventKitActionCommitter: ActionCommitting {
    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    func requestEventsAccessIfNeeded() async -> ActionAccessResult {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .writeOnly, .authorized:
            return .granted
        case .notDetermined:
            do {
                return try await store.requestWriteOnlyAccessToEvents() ? .granted : .denied
            } catch {
                return .denied
            }
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestRemindersAccessIfNeeded() async -> ActionAccessResult {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .fullAccess, .authorized:
            return .granted
        case .notDetermined:
            do {
                return try await store.requestFullAccessToReminders() ? .granted : .denied
            } catch {
                return .denied
            }
        case .denied, .restricted, .writeOnly:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func makePrefilledEvent(from action: ProposedAction) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = action.title
        let start = action.start ?? action.due ?? Date()
        event.startDate = start
        event.endDate = action.end ?? start.addingTimeInterval(60 * 60)
        event.isAllDay = action.isAllDay
        event.location = action.location
        if let urlString = action.url, let url = URL(string: urlString) {
            event.url = url
        }
        let noteParts = [action.sourceSpan, action.people.isEmpty ? nil : action.people.joined(separator: ", ")]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        event.notes = noteParts.isEmpty ? nil : noteParts.joined(separator: "\n")
        return event
    }

    func saveReminder(title: String, notes: String?, due: Date?, url: String?) throws -> String {
        guard let calendar = store.defaultCalendarForNewReminders() else {
            throw ActionCommitError.missingCalendar
        }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        var noteBody = [notes, url.map { "Link: \($0)" }].compactMap { $0 }.joined(separator: "\n")
        reminder.notes = noteBody.isEmpty ? nil : noteBody
        if let due {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: due
            )
            reminder.addAlarm(EKAlarm(absoluteDate: due))
        }
        reminder.calendar = calendar
        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }
}

final class FakeActionCommitter: ActionCommitting, @unchecked Sendable {
    var eventsAccess: ActionAccessResult = .granted
    var remindersAccess: ActionAccessResult = .granted
    var savedReminderIdentifier = "fake-reminder-id"
    var shouldFailSave = false
    private(set) var eventsAccessRequestCount = 0
    private(set) var remindersAccessRequestCount = 0
    private(set) var savedReminders: [(title: String, notes: String?, due: Date?, url: String?)] = []

    func requestEventsAccessIfNeeded() async -> ActionAccessResult {
        eventsAccessRequestCount += 1
        return eventsAccess
    }

    func requestRemindersAccessIfNeeded() async -> ActionAccessResult {
        remindersAccessRequestCount += 1
        return remindersAccess
    }

    func makePrefilledEvent(from action: ProposedAction) -> EKEvent {
        EKEvent(eventStore: EKEventStore())
    }

    func saveReminder(title: String, notes: String?, due: Date?, url: String?) throws -> String {
        if shouldFailSave { throw ActionCommitError.saveFailed }
        savedReminders.append((title, notes, due, url))
        return savedReminderIdentifier
    }
}

enum ActionDeepLink {
    static func calendarURL(for action: ProposedAction) -> URL? {
        guard action.kind == .event else { return nil }
        guard let anchor = action.start ?? action.due else { return nil }
        return URL(string: "calshow:\(Int(anchor.timeIntervalSinceReferenceDate))")
    }

    static func remindersURL(for action: ProposedAction) -> URL? {
        guard action.kind == .reminder || action.kind == .followUp else { return nil }
        guard let identifier = action.ekIdentifier else { return URL(string: "x-apple-reminderkit://") }
        var components = URLComponents(string: "x-apple-reminderkit://identify")
        components?.queryItems = [URLQueryItem(name: "identifier", value: identifier)]
        return components?.url
    }
}
