import AppKit
import SwiftUI

enum ReaderPresentationSettings {
    private static let colorKey = "readerPresentation.textColor"
    private static let opacityKey = "readerPresentation.textOpacity"

    static func textColor(in defaults: UserDefaults = .standard) -> Color {
        let stored = defaults.string(forKey: colorKey) ?? "#1D1D1F"
        return Color(nsColor: NSColor(hex: stored) ?? .labelColor)
    }

    static func textOpacity(in defaults: UserDefaults = .standard) -> Double {
        min(max(defaults.object(forKey: opacityKey) as? Double ?? 1, 0), 1)
    }

    static var textColor: Color { textColor(in: .standard) }
    static var textOpacity: Double { textOpacity(in: .standard) }

    static func save(color: Color, opacity: Double, to defaults: UserDefaults = .standard) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? .labelColor
        defaults.set(nsColor.hexString, forKey: colorKey)
        defaults.set(min(max(opacity, 0), 1), forKey: opacityKey)
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let rgb = Int(value, radix: 16) else { return nil }
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }

    var hexString: String {
        let color = usingColorSpace(.sRGB) ?? self
        return String(format: "#%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255))
    }
}
