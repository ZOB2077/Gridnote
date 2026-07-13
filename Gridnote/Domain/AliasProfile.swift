import Foundation

enum OfficeTemplateFamily: String, Codable, CaseIterable, Hashable, Sendable {
    case operations
    case projectTracking
    case budget
    case notes

    var disguiseTitle: String {
        switch self {
        case .operations: "明细数据"
        case .projectTracking: "渠道转化日报"
        case .budget: "库存履约周报"
        case .notes: "设备巡检台账"
        }
    }

    var defaultSheetName: String {
        switch self {
        case .operations: "5_明细数据"
        case .projectTracking: "渠道日报"
        case .budget: "库存履约"
        case .notes: "设备台账"
        }
    }
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
