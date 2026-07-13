import Foundation

enum OfficeTemplateFamily: String, Codable, CaseIterable, Sendable {
    case operations
    case projectTracking
    case budget
    case notes
}

struct AliasProfile: Codable, Equatable, Sendable {
    var aliasTitle: String
    var workbookTitle: String
    var sheetName: String
    var templateFamily: OfficeTemplateFamily

    init(
        aliasTitle: String,
        workbookTitle: String,
        sheetName: String,
        templateFamily: OfficeTemplateFamily = .operations
    ) {
        self.aliasTitle = aliasTitle
        self.workbookTitle = workbookTitle
        self.sheetName = sheetName
        self.templateFamily = templateFamily
    }
}
