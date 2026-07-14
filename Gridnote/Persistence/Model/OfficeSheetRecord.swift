import Foundation
import SwiftData

@Model
final class OfficeSheetRecord {
    @Attribute(.unique) var id: UUID
    var bookID: UUID?
    var activeSheetName: String
    var selectedRow: Int
    var selectedColumn: Int
    var scrollPosition: Double
    var templateFamilyRawValue: String
    var gridValuesData: Data
    var lastInjectedExcerptData: Data?

    init(
        id: UUID = UUID(),
        bookID: UUID? = nil,
        activeSheetName: String = "Overview",
        templateFamily: OfficeTemplateFamily = .operations
    ) {
        self.id = id
        self.bookID = bookID
        self.activeSheetName = activeSheetName
        self.selectedRow = 0
        self.selectedColumn = 0
        self.scrollPosition = 0
        self.templateFamilyRawValue = templateFamily.rawValue
        self.gridValuesData = Data()
        self.lastInjectedExcerptData = nil
    }
}
