import SwiftData
import XCTest
@testable import Capture

@MainActor
final class ProposedActionApprovalTests: XCTestCase {
    func testDismissSetsStatus() {
        let action = makeAction()
        let service = ProposedActionApprovalService(committer: FakeActionCommitter())

        service.dismiss(action)

        XCTAssertEqual(action.status, .dismissed)
    }

    func testMarkApprovedStoresIdentifier() {
        let action = makeAction()
        let service = ProposedActionApprovalService(committer: FakeActionCommitter())

        service.markApproved(action, ekIdentifier: "event-123")

        XCTAssertEqual(action.status, .approved)
        XCTAssertEqual(action.ekIdentifier, "event-123")
    }

    func testMarkFailedSetsStatus() {
        let action = makeAction()
        let service = ProposedActionApprovalService(committer: FakeActionCommitter())

        service.markFailed(action)

        XCTAssertEqual(action.status, .failed)
    }

    func testRetryResetsFailedActionToProposed() {
        let action = makeAction(status: .failed, ekIdentifier: "old")
        let service = ProposedActionApprovalService(committer: FakeActionCommitter())

        service.retry(action)

        XCTAssertEqual(action.status, .proposed)
        XCTAssertNil(action.ekIdentifier)
    }

    func testEnsureAccessDeniedForEvents() async {
        let committer = FakeActionCommitter()
        committer.eventsAccess = .denied
        let service = ProposedActionApprovalService(committer: committer)

        let result = await service.ensureAccess(for: .event)

        XCTAssertEqual(result, .failure(.accessDenied(.event)))
        XCTAssertEqual(committer.eventsAccessRequestCount, 1)
    }

    func testEnsureAccessDeniedForReminders() async {
        let committer = FakeActionCommitter()
        committer.remindersAccess = .denied
        let service = ProposedActionApprovalService(committer: committer)

        let result = await service.ensureAccess(for: .reminder)

        XCTAssertEqual(result, .failure(.accessDenied(.reminder)))
        XCTAssertEqual(committer.remindersAccessRequestCount, 1)
    }

    func testSaveReminderApprovesOnSuccess() throws {
        let committer = FakeActionCommitter()
        let service = ProposedActionApprovalService(committer: committer)
        let action = makeAction(kind: .reminder)

        let identifier = try service.saveReminder(action: action, title: "Buy milk", due: .now)

        XCTAssertEqual(identifier, "fake-reminder-id")
        XCTAssertEqual(action.status, .approved)
        XCTAssertEqual(action.ekIdentifier, "fake-reminder-id")
        XCTAssertEqual(committer.savedReminders.count, 1)
        XCTAssertEqual(committer.savedReminders.first?.title, "Buy milk")
    }

    func testSaveReminderMarksFailedWhenCommitterThrows() {
        let committer = FakeActionCommitter()
        committer.shouldFailSave = true
        let service = ProposedActionApprovalService(committer: committer)
        let action = makeAction(kind: .reminder)

        XCTAssertThrowsError(try service.saveReminder(action: action, title: "Buy milk", due: .now))
        XCTAssertEqual(action.status, .proposed)
    }

    func testCalendarDeepLinkUsesStartDate() {
        let action = makeAction(kind: .event, start: Date(timeIntervalSinceReferenceDate: 100_000))
        let url = ActionDeepLink.calendarURL(for: action)

        XCTAssertEqual(url?.absoluteString, "calshow:100000")
    }

    private func makeAction(
        kind: ProposedActionKind = .event,
        status: ProposedActionStatus = .proposed,
        start: Date? = Date(),
        ekIdentifier: String? = nil
    ) -> ProposedAction {
        ProposedAction(
            kind: kind,
            title: "Test",
            start: start,
            confidence: 0.9,
            status: status,
            ekIdentifier: ekIdentifier
        )
    }
}
