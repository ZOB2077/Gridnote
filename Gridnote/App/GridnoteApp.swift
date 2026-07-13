import SwiftUI
import SwiftData

@main
struct GridnoteApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var stealthController: StealthOverlayController
    private let modelContainer: ModelContainer

    init() {
        do {
            let container = try GridnoteModelContainer.make()
            modelContainer = container
            _stealthController = StateObject(
                wrappedValue: StealthOverlayController(context: container.mainContext)
            )
        } catch {
            fatalError("Unable to initialize Gridnote storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(appState)
                .environmentObject(stealthController)
        }
        .modelContainer(modelContainer)

        MenuBarExtra("Data Hub", systemImage: "chart.bar.doc.horizontal") {
            StealthMenuBarView()
                .environmentObject(stealthController)
        }
    }
}
