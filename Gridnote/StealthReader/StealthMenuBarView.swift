import AppKit
import SwiftUI

struct StealthMenuBarView: View {
    @EnvironmentObject private var stealthController: StealthOverlayController

    var body: some View {
        if stealthController.superStealthMode {
            Text("Super Stealth Controls")
                .font(.headline)
            Text("Text-only floating reader is active")
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            Button("Show Floating Reader") {
                stealthController.show(bookID: nil)
            }
            Button(String(format: String(localized: "Show / Hide  %@"), stealthController.toggleShortcut.title)) {
                stealthController.toggleVisibility()
            }
            Button(String(format: String(localized: "Previous Page  %@"), stealthController.previousShortcut.title)) {
                stealthController.previous()
            }
            Button(String(format: String(localized: "Next Page  %@"), stealthController.nextShortcut.title)) {
                stealthController.next()
            }
            if !stealthController.viewModel.chapters.isEmpty {
                Menu("Chapters") {
                    ForEach(stealthController.viewModel.chapters) { chapter in
                        Button(chapter.title) { stealthController.viewModel.jump(to: chapter) }
                    }
                }
            }
        } else {
            Button("Show Floating Reader") {
                stealthController.show(bookID: nil)
            }
        }
        Divider()
        Button("Open Data Hub") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
        }
    }
}
