import Foundation

enum OfficeTemplateFamily: String, Codable, CaseIterable, Hashable, Sendable {
    case operations
    case projectTracking
    case budget
    case notes

    var disguiseTitle: String {
        switch self {
        case .operations: "设备租赁明细"
        case .projectTracking: "订单进度跟踪"
        case .budget: "仓配履约清单"
        case .notes: "设备巡检台账"
        }
    }

    var defaultSheetName: String {
        switch self {
        case .operations: "订单明细"
        case .projectTracking: "订单进度"
        case .budget: "仓配履约"
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
