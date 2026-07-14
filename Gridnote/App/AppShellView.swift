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
        .navigationTitle(windowTitle)
        .toolbar {
            ToolbarItemGroup {
                Button { isLibraryPresented = true } label: {
                    Label("数据文件", systemImage: "books.vertical")
                }
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
                    .help("Data Files")
                    .accessibilityIdentifier("show-library")
                Button { isSettingsPresented = true } label: {
                    Label("设置", systemImage: "gearshape")
                }
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
                    .help("Workspace Options")
                    .accessibilityIdentifier("show-settings")
                Button(action: showStealthReader) {
                    Label("悬浮阅读", systemImage: "rectangle.on.rectangle")
                }
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
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
