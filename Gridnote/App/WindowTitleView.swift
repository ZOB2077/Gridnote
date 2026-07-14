import AppKit
import SwiftUI

struct WindowTitleView: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        update(title: title, for: view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) { update(title: title, for: view) }

    private func update(title: String, for view: NSView) {
        DispatchQueue.main.async { view.window?.title = title }
    }
}
