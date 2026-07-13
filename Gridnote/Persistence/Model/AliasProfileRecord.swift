import Foundation
import SwiftData

@Model
final class AliasProfileRecord {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var aliasTitle: String
    var workbookTitle: String
    var sheetName: String
    var templateFamilyRawValue: String

    init(
        id: UUID = UUID(),
        bookID: UUID,
        profile: AliasProfile
    ) {
        self.id = id
        self.bookID = bookID
        self.aliasTitle = profile.aliasTitle
        self.workbookTitle = profile.workbookTitle
        self.sheetName = profile.sheetName
        self.templateFamilyRawValue = profile.templateFamily.rawValue
    }

    var profile: AliasProfile {
        get {
            AliasProfile(
                aliasTitle: aliasTitle,
                workbookTitle: workbookTitle,
                sheetName: sheetName,
                templateFamily: OfficeTemplateFamily(rawValue: templateFamilyRawValue) ?? .operations
            )
        }
        set {
            aliasTitle = newValue.aliasTitle
            workbookTitle = newValue.workbookTitle
            sheetName = newValue.sheetName
            templateFamilyRawValue = newValue.templateFamily.rawValue
        }
    }
}
