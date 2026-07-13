import SwiftUI
import SwiftData
import AppKit

final class DataHubApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // SwiftUI builds the default application menu from the executable name.
        DispatchQueue.main.async {
            DataHubApplicationDelegate.applyMenuTitle()
        }
    }

    @MainActor
    static func applyMenuTitle() {
        NSApp.mainMenu?.item(at: 0)?.title = "Data Hub"
        NSApp.mainMenu?.item(at: 0)?.submenu?.title = "Data Hub"
    }
}

@main
struct GridnoteApp: App {
    @NSApplicationDelegateAdaptor(DataHubApplicationDelegate.self) private var applicationDelegate
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
