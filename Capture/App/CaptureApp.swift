import SwiftUI
import SwiftData

@main
struct CaptureApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try CapturePersistence.makeContainer(
                inMemory: ProcessInfo.processInfo.arguments.contains("--ui-testing")
            )
        } catch {
            fatalError("Capture could not open its local store: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView(container: container)
        }
        .modelContainer(container)
    }
}
