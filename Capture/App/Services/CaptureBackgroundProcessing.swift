import BackgroundTasks
import Foundation
import SwiftData

enum CaptureBackgroundTaskIdentifier {
    static let processing = "com.rudy.capture.processing"
}

protocol CaptureBackgroundScheduling: Sendable {
    func register(processingHandler: @escaping @Sendable () async -> Void)
    func scheduleProcessing(earliestBeginDate: Date)
}

final class CaptureBackgroundTaskScheduler: CaptureBackgroundScheduling, @unchecked Sendable {
    static let shared = CaptureBackgroundTaskScheduler()

    private var handler: (@Sendable () async -> Void)?

    func register(processingHandler: @escaping @Sendable () async -> Void) {
        handler = processingHandler
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: CaptureBackgroundTaskIdentifier.processing,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            processingTask.expirationHandler = {
                processingTask.setTaskCompleted(success: false)
            }
            let work = self.handler
            Task {
                await work?()
                processingTask.setTaskCompleted(success: true)
            }
        }
    }

    func scheduleProcessing(earliestBeginDate: Date = Date(timeIntervalSinceNow: 60)) {
        let request = BGProcessingTaskRequest(identifier: CaptureBackgroundTaskIdentifier.processing)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = earliestBeginDate
        try? BGTaskScheduler.shared.submit(request)
    }
}

final class FakeCaptureBackgroundScheduler: CaptureBackgroundScheduling, @unchecked Sendable {
    private(set) var scheduledDates: [Date] = []
    private(set) var registrationCount = 0
    var processingHandler: (@Sendable () async -> Void)?

    func register(processingHandler: @escaping @Sendable () async -> Void) {
        registrationCount += 1
        self.processingHandler = processingHandler
    }

    func scheduleProcessing(earliestBeginDate: Date) {
        scheduledDates.append(earliestBeginDate)
    }

    func runProcessing() async {
        await processingHandler?()
    }
}

@MainActor
struct CaptureBackgroundDrainer {
    let coordinator: EnrichmentCoordinator
    let intentService: RemindMeIntentService

    init(
        coordinator: EnrichmentCoordinator = EnrichmentCoordinator(),
        intentService: RemindMeIntentService = RemindMeIntentService()
    ) {
        self.coordinator = coordinator
        self.intentService = intentService
    }

    func drain(modelContext: ModelContext) async throws {
        try intentService.applyPendingIntents(modelContext: modelContext)
        let contexts = try modelContext.fetch(FetchDescriptor<CaptureContext>())
        let items = try modelContext.fetch(FetchDescriptor<CaptureItem>())
        let pending = items.filter { $0.enrichmentState == .pending || $0.enrichmentState == .failed }
        for item in pending {
            await coordinator.process(item, contexts: contexts, modelContext: modelContext)
        }
        try modelContext.save()
    }

    @MainActor
    static func drainStoredCaptures(container: ModelContainer, coordinator: EnrichmentCoordinator = EnrichmentCoordinator()) async {
        let drainer = CaptureBackgroundDrainer(coordinator: coordinator)
        try? await drainer.drain(modelContext: container.mainContext)
    }
}
