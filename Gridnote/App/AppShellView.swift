import SwiftUI
import SwiftData
import AppKit

struct AppShellView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var stealthController: StealthOverlayController
    @Environment(\.modelContext) private var modelContext
    @State private var isLibraryPresented = false
    @State private var isSettingsPresented = false
    @State private var windowTitle = "Operations Dashboard.xlsx"

    var body: some View {
        OfficeWorkspaceView()
        .frame(minWidth: 720, minHeight: 480)
        .background(WindowTitleView(title: windowTitle).frame(width: 0, height: 0))
        .toolbar {
            ToolbarItem {
                Button { isLibraryPresented = true } label: { Image(systemName: "tray.full") }
                    .help("Data Files")
                    .accessibilityIdentifier("show-library")
            }
            ToolbarItem {
                Button { isSettingsPresented = true } label: { Image(systemName: "slider.horizontal.3") }
                    .help("Workspace Options")
                    .accessibilityIdentifier("show-settings")
            }
            ToolbarItem {
                Button(action: showStealthReader) { Image(systemName: "rectangle.dashed") }
                    .help("Quick Panel")
                    .accessibilityIdentifier("show-floating-reader")
            }
        }
        .sheet(isPresented: $isLibraryPresented) { LibraryView() }
        .sheet(isPresented: $isSettingsPresented) { SettingsView() }
        .task(id: appState.selectedBookID) {
            updateWindowTitle()
            stealthController.setCurrentBook(appState.selectedBookID)
        }
        .onAppear(perform: updateApplicationMenuTitle)
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteAliasDidChange)) { _ in updateWindowTitle() }
    }

    private func updateWindowTitle() {
        guard let bookID = appState.selectedBookID,
              let alias = try? AliasProfileRepository(context: modelContext).fetch(bookID: bookID) else {
            windowTitle = "Operations Dashboard.xlsx"
            return
        }
        windowTitle = alias.workbookTitle.isEmpty ? alias.aliasTitle : alias.workbookTitle
    }

    private func showStealthReader() {
        stealthController.show(bookID: appState.selectedBookID)
    }

    private func updateApplicationMenuTitle() {
        DispatchQueue.main.async {
            DataHubApplicationDelegate.applyMenuTitle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            DataHubApplicationDelegate.applyMenuTitle()
        }
    }
}

#Preview {
    AppShellView()
        .environmentObject(AppState())
}
