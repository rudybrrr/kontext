/*
 THESIS: Capture is an immediate intake surface that removes filing decisions; it refuses folder-first navigation and dashboard furniture.
 OWN-WORLD: Native iOS utility—semantic system grounds, one system-blue action, SF Symbols, inset lists, and unmodified system typography and materials.
 STORY: Save first, see the capture appear, let on-device understanding organize it, then retrieve or correct it without ceremony.
 FIRST VIEWPORT: A large Capture title and trailing search/settings controls lead into one full-width capture action, followed by current contexts and recent items; the primary action remains above the first scroll.
 FORM: User-pinned native Apple utility canon, overriding the assigned fourth direction from concept-roll seed 88bb798e.
 FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
*/

import SwiftUI
import SwiftData

@main
struct CaptureApp: App {
    @UIApplicationDelegateAdaptor(CaptureAppDelegate.self) private var appDelegate
    private let container: ModelContainer
    private let backgroundScheduler: CaptureBackgroundScheduling

    init() {
        let scheduler = CaptureBackgroundTaskScheduler.shared
        backgroundScheduler = scheduler
        do {
            container = try CapturePersistence.makeContainer(
                inMemory: ProcessInfo.processInfo.arguments.contains("--ui-testing")
            )
        } catch {
            fatalError("Kontext could not open its local store: \(error.localizedDescription)")
        }

        guard !ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--ui-testing") }) else { return }
        let modelContainer = container
        scheduler.register {
            await CaptureBackgroundDrainer.drainStoredCaptures(container: modelContainer)
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView(container: container, backgroundScheduler: backgroundScheduler)
        }
        .modelContainer(container)
    }
}
