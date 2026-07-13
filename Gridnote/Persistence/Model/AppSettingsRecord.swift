import Foundation
import SwiftData

@Model
final class AppSettingsRecord {
    @Attribute(.unique) var id: UUID
    var resignToOfficeOnDeactivate: Bool
    var defaultWorkspaceModeRawValue: String
    var standardReaderFontSize: Double
    var standardReaderLineHeight: Double?
    var readerThemeRawValue: String

    init(
        id: UUID = UUID(),
        resignToOfficeOnDeactivate: Bool = false,
        defaultWorkspaceModeRawValue: String = "office",
        standardReaderFontSize: Double = 18,
        standardReaderLineHeight: Double? = nil,
        readerThemeRawValue: String = "system"
    ) {
        self.id = id
        self.resignToOfficeOnDeactivate = resignToOfficeOnDeactivate
        self.defaultWorkspaceModeRawValue = defaultWorkspaceModeRawValue
        self.standardReaderFontSize = standardReaderFontSize
        self.standardReaderLineHeight = standardReaderLineHeight
        self.readerThemeRawValue = readerThemeRawValue
    }
}
