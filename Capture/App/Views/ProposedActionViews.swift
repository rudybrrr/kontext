import EventKit
import EventKitUI
import SwiftData
import SwiftUI

struct SuggestedActionsSection: View {
    @Bindable var item: CaptureItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var approvalService = ProposedActionApprovalService()
    @State private var eventEditContext: EventEditContext?
    @State private var reminderSheetAction: ProposedAction?
    @State private var accessDeniedKind: ProposedActionKind?
    @State private var errorMessage: String?

    private var visibleActions: [ProposedAction] {
        item.proposedActions.sorted { lhs, rhs in
            if lhs.status == rhs.status { return lhs.confidence > rhs.confidence }
            return lhs.status.sortOrder < rhs.status.sortOrder
        }
    }

    var body: some View {
        Group {
            if !visibleActions.isEmpty {
                Section("Suggested actions") {
                    ForEach(visibleActions) { action in
                        ProposedActionCard(
                            action: action,
                            onApprove: { await approve(action) },
                            onDismiss: { dismiss(action) },
                            onRetry: { retry(action) },
                            onOpenExternal: { openExternal(action) }
                        )
                    }
                }
            }
        }
        .sheet(item: $eventEditContext) { context in
            EventEditRepresentable(
                event: context.event,
                onComplete: { result in
                    handleEventEditResult(result, action: context.action)
                    eventEditContext = nil
                }
            )
        }
        .sheet(item: $reminderSheetAction) { action in
            ReminderApprovalSheet(
                action: action,
                approvalService: approvalService,
                onComplete: { result in
                    switch result {
                    case .success:
                        save()
                    case .cancelled:
                        break
                    case .failure(.accessDenied):
                        accessDeniedKind = action.kind
                    case .failure(.saveFailed):
                        approvalService.markFailed(action)
                        save()
                    }
                    reminderSheetAction = nil
                }
            )
        }
        .alert(
            "Permission Needed",
            isPresented: Binding(
                get: { accessDeniedKind != nil },
                set: { if !$0 { accessDeniedKind = nil } }
            )
        ) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
                accessDeniedKind = nil
            }
            Button("Cancel", role: .cancel) { accessDeniedKind = nil }
        } message: {
            Text(accessDeniedMessage)
        }
        .alert("Could Not Save", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func dismiss(_ action: ProposedAction) {
        approvalService.dismiss(action)
        save()
    }

    private func retry(_ action: ProposedAction) {
        approvalService.retry(action)
        save()
        Task { await approve(action) }
    }

    @MainActor
    private func approve(_ action: ProposedAction) async {
        switch await approvalService.ensureAccess(for: action.kind) {
        case .failure:
            accessDeniedKind = action.kind
            return
        case .success:
            break
        }

        switch action.kind {
        case .event:
            let event = approvalService.prefilledEvent(for: action)
            eventEditContext = EventEditContext(action: action, event: event)
        case .reminder, .followUp:
            reminderSheetAction = action
        }
    }

    private func openExternal(_ action: ProposedAction) {
        if let url = ActionDeepLink.calendarURL(for: action) ?? ActionDeepLink.remindersURL(for: action) {
            openURL(url)
        }
    }

    private func save() {
        do { try modelContext.save() } catch { errorMessage = error.localizedDescription }
    }

    private var accessDeniedMessage: String {
        switch accessDeniedKind {
        case .event:
            "Capture needs write-only Calendar access when you approve an event. Enable it in Settings."
        case .reminder, .followUp:
            "Capture needs Reminders access when you approve a reminder. Enable it in Settings."
        case .none:
            ""
        }
    }

    private func handleEventEditResult(_ result: EventEditResult, action: ProposedAction) {
        switch result {
        case .saved(let identifier):
            approvalService.markApproved(action, ekIdentifier: identifier)
            save()
        case .cancelled:
            break
        case .failed:
            approvalService.markFailed(action)
            save()
        }
    }
}

private struct EventEditContext: Identifiable {
    let id = UUID()
    let action: ProposedAction
    let event: EKEvent
}

struct ProposedActionCard: View {
    let action: ProposedAction
    let onApprove: () async -> Void
    let onDismiss: () -> Void
    let onRetry: () -> Void
    let onOpenExternal: () -> Void

    @State private var isApproving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(action.kind.displayName, systemImage: action.kind.symbolName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(action.confidence, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(action.title)
                .font(.headline)

            if let schedule = action.scheduleSummary {
                LabeledContent("When", value: schedule)
                    .font(.subheadline)
            }

            if let location = action.location, !location.isEmpty {
                LabeledContent("Where", value: location)
                    .font(.subheadline)
            }

            if let span = action.sourceSpan, !span.isEmpty {
                Text(span)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }

            statusFooter
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusFooter: some View {
        switch action.status {
        case .proposed:
            HStack {
                Button("Dismiss", role: .destructive, action: onDismiss)
                Spacer()
                Button {
                    isApproving = true
                    Task {
                        await onApprove()
                        isApproving = false
                    }
                } label: {
                    if isApproving {
                        ProgressView()
                    } else {
                        Text("Approve")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isApproving)
            }
        case .approved:
            VStack(alignment: .leading, spacing: 8) {
                Label("Approved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                if action.kind == .event, ActionDeepLink.calendarURL(for: action) != nil {
                    Button("Open in Calendar", systemImage: "calendar", action: onOpenExternal)
                        .font(.subheadline)
                } else if ActionDeepLink.remindersURL(for: action) != nil {
                    Button("Open in Reminders", systemImage: "checklist", action: onOpenExternal)
                        .font(.subheadline)
                }
            }
        case .dismissed:
            Label("Dismissed", systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        case .failed:
            VStack(alignment: .leading, spacing: 8) {
                Label("Could not save", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                Button("Retry", systemImage: "arrow.clockwise", action: onRetry)
            }
        }
    }
}

struct EventEditRepresentable: UIViewControllerRepresentable {
    let event: EKEvent
    let onComplete: (EventEditResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = event.eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onComplete: (EventEditResult) -> Void

        init(onComplete: @escaping (EventEditResult) -> Void) {
            self.onComplete = onComplete
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            switch action {
            case .saved:
                if let identifier = controller.event?.eventIdentifier {
                    onComplete(.saved(identifier))
                } else {
                    onComplete(.failed)
                }
            case .cancelled, .deleted:
                onComplete(.cancelled)
            @unknown default:
                onComplete(.cancelled)
            }
        }
    }
}

enum EventEditResult {
    case saved(String)
    case cancelled
    case failed
}

struct ReminderApprovalSheet: View {
    @Bindable var action: ProposedAction
    let approvalService: ProposedActionApprovalService
    let onComplete: (ReminderApprovalResult) -> Void

    @State private var title: String
    @State private var due: Date
    @State private var hasDue: Bool
    @State private var isSaving = false

    init(action: ProposedAction, approvalService: ProposedActionApprovalService, onComplete: @escaping (ReminderApprovalResult) -> Void) {
        self.action = action
        self.approvalService = approvalService
        self.onComplete = onComplete
        _title = State(initialValue: action.title)
        let initialDue = action.due ?? action.start ?? .now.addingTimeInterval(3600)
        _due = State(initialValue: initialDue)
        _hasDue = State(initialValue: action.due != nil || action.start != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Title", text: $title)
                    Toggle("Due date", isOn: $hasDue)
                    if hasDue {
                        DatePicker("Due", selection: $due)
                    }
                    if let span = action.sourceSpan {
                        Text(span)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Approve reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onComplete(.cancelled) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task { @MainActor in
            switch await approvalService.ensureAccess(for: action.kind) {
            case .failure:
                onComplete(.failure(.accessDenied))
                isSaving = false
                return
            case .success:
                break
            }
            do {
                _ = try approvalService.saveReminder(
                    action: action,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    due: hasDue ? due : nil
                )
                onComplete(.success)
            } catch {
                onComplete(.failure(.saveFailed))
            }
            isSaving = false
        }
    }
}

enum ReminderApprovalResult {
    case success
    case cancelled
    case failure(ReminderApprovalFailure)
}

enum ReminderApprovalFailure {
    case accessDenied
    case saveFailed
}

extension ProposedAction {
    var scheduleSummary: String? {
        switch kind {
        case .event:
            guard let start else { return nil }
            if isAllDay {
                return start.formatted(date: .abbreviated, time: .omitted)
            }
            if let end {
                return "\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(time: .shortened))"
            }
            return start.formatted(date: .abbreviated, time: .shortened)
        case .reminder, .followUp:
            guard let due else { return nil }
            return due.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

extension ProposedActionKind {
    var displayName: String {
        switch self {
        case .event: "Event"
        case .reminder: "Reminder"
        case .followUp: "Follow-up"
        }
    }

    var symbolName: String {
        switch self {
        case .event: "calendar"
        case .reminder: "bell"
        case .followUp: "link"
        }
    }
}

extension ProposedActionStatus {
    var sortOrder: Int {
        switch self {
        case .proposed: 0
        case .failed: 1
        case .approved: 2
        case .dismissed: 3
        }
    }
}

extension ProposedAction: Identifiable {}
