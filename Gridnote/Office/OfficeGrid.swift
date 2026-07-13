import Foundation

struct OfficeCellCoordinate: Hashable, Codable, Equatable {
    let row: Int
    let column: Int

    var name: String { "\(Self.columnName(column))\(row + 1)" }

    static func columnName(_ column: Int) -> String {
        var value = column + 1
        var result = ""
        while value > 0 {
            value -= 1
            result = String(UnicodeScalar(65 + value % 26)!) + result
            value /= 26
        }
        return result
    }
}

struct OfficeGridSnapshot: Codable, Equatable {
    static let rowCount = 25
    static let columnCount = 18

    var values: [OfficeCellCoordinate: String]

    subscript(_ coordinate: OfficeCellCoordinate) -> String {
        get { values[coordinate, default: ""] }
        set {
            if newValue.isEmpty { values.removeValue(forKey: coordinate) }
            else { values[coordinate] = newValue }
        }
    }

    // Every built-in table is deterministic synthetic data and contains no customer or business records.
    static var defaultOperations: OfficeGridSnapshot {
        let headers = ["演示日期", "业务单元", "渠道类型", "演示渠道", "设备型号", "申请量", "初审通过", "初审通过率", "签约发起", "签约完成", "签约率", "审核完成", "审核完成率", "进入履约", "可处理", "处理成功", "最终完成", "完成率"]
        let rows = (0..<(rowCount - 1)).map { index in
            let applications = 18 + index % 13
            let approved = max(1, applications - 2 - index % 4)
            let signed = max(1, approved - 1 - index % 3)
            let completed = max(0, signed - index % 2)
            return [
                String(format: "2026-07-%02d", 1 + index % 7),
                "演示业务 \(letter(index % 3))",
                index.isMultiple(of: 2) ? "演示直营" : "演示合作",
                "模拟渠道 \(letter(index % 4))",
                String(format: "测试设备 G-%02d", index + 1),
                "\(applications)", "\(approved)", percentage(approved, of: applications),
                "\(approved)", "\(signed)", percentage(signed, of: approved),
                "\(signed)", "100.00%", "\(signed)", "\(signed)",
                "\(completed)", "\(completed)", percentage(completed, of: signed)
            ]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    static func snapshot(for template: OfficeTemplateFamily) -> OfficeGridSnapshot {
        switch template {
        case .operations: defaultOperations
        case .projectTracking: channelConversion
        case .budget: inventoryFulfillment
        case .notes: deviceLedger
        }
    }

    static var channelConversion: OfficeGridSnapshot {
        let headers = ["演示日期", "活动代号", "区域", "演示渠道", "设备型号", "展示量", "访问量", "意向量", "申请量", "完成量", "完成率", "初审通过", "签约完成", "签约率", "进入履约", "履约完成", "最终完成", "备注"]
        let rows = (0..<(rowCount - 1)).map { index in
            let exposure = 260 + index * 37
            let visits = 74 + index * 9
            let orders = 4 + index % 7
            let completed = max(1, orders - index % 3)
            let approved = max(1, completed - 1)
            let fulfilled = max(0, completed - 2)
            return [
                "2026-07-01", "演示活动", "区域 \(index % 4 + 1)",
                "模拟渠道 \(index % 4 + 1)", String(format: "测试设备 C-%02d", index + 1),
                "\(exposure)", "\(visits)", "\(orders + 6)", "\(orders)", "\(completed)",
                percentage(completed, of: visits), "\(approved)", "\(approved)",
                percentage(approved, of: completed), "\(fulfilled)", "\(fulfilled)", "\(fulfilled)",
                index.isMultiple(of: 5) ? "演示关注" : "演示正常"
            ]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    static var inventoryFulfillment: OfficeGridSnapshot {
        let headers = ["演示日期", "仓库", "区域", "演示渠道", "设备型号", "使用中", "可用库存", "调拨中", "近期申请", "待审核", "处理中", "待交付", "已完成", "回收中", "完成率", "周转天数", "库存提示", "处理建议"]
        let rows = (0..<(rowCount - 1)).map { index in
            let available = 8 + index % 18
            let pending = 1 + index % 5
            let processing = 2 + index % 6
            let completed = processing + 4
            return [
                "2026-07-01", "演示仓 \(index % 2 + 1)", "区域 \(index % 6 + 1)",
                "模拟渠道 \(index % 3 + 1)", String(format: "测试设备 I-%02d", index + 1),
                "\(42 + index * 3)", "\(available)", "\(index % 4)", "\(6 + index % 8)",
                "\(pending)", "\(processing)", "\(max(1, pending - 1))", "\(completed)", "\(index % 3)",
                percentage(completed, of: completed + pending), "\(14 + index % 12)",
                available < 12 ? "演示补充" : "演示充足", available < 12 ? "模拟调拨" : "常规跟进"
            ]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    static var deviceLedger: OfficeGridSnapshot {
        let headers = ["演示日期", "资产编号", "区域", "演示网点", "设备型号", "设备状态", "流程状态", "本期费用", "保证金", "使用时长", "最近检查", "电池状态", "屏幕状态", "外观等级", "配件状态", "预计回收", "风险等级", "处理备注"]
        let rows = (0..<(rowCount - 1)).map { index in
            let days = 18 + index * 3
            return [
                "2026-07-01", String(format: "DEMO-%04d", 1000 + index), "区域 \(index % 4 + 1)",
                "演示网点 \(index % 5 + 1)", String(format: "测试设备 L-%02d", index + 1),
                index.isMultiple(of: 6) ? "待检" : "可用", index.isMultiple(of: 4) ? "待处理" : "处理中",
                "¥\(100 + index * 10)", "¥\(500 + index * 20)", "\(days) 天",
                String(format: "2026-07-%02d", 1 + index % 9), "\(83 + index % 15)%",
                index.isMultiple(of: 7) ? "演示瑕疵" : "良好", index.isMultiple(of: 5) ? "B" : "A",
                index.isMultiple(of: 8) ? "待补充" : "齐全", String(format: "2026-08-%02d", 1 + index % 20),
                index.isMultiple(of: 6) ? "演示中" : "演示低", index.isMultiple(of: 6) ? "模拟检查" : "演示正常"
            ]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    private static func denseSnapshot(headers: [String], rows: [[String]]) -> OfficeGridSnapshot {
        var snapshot = OfficeGridSnapshot(values: [:])
        for (rowIndex, row) in ([headers] + rows).prefix(rowCount).enumerated() {
            for columnIndex in 0..<columnCount {
                snapshot[OfficeCellCoordinate(row: rowIndex, column: columnIndex)] = row.indices.contains(columnIndex) ? row[columnIndex] : "-"
            }
        }
        return snapshot
    }

    private static func percentage(_ value: Int, of total: Int) -> String {
        guard total > 0 else { return "0.00%" }
        return String(format: "%.2f%%", Double(value) / Double(total) * 100)
    }

    private static func letter(_ offset: Int) -> Character {
        Character(UnicodeScalar(65 + offset)!)
    }

    var isLegacyOperationsTemplate: Bool {
        let firstHeader = self[OfficeCellCoordinate(row: 0, column: 0)]
        return firstHeader == "Date" || firstHeader == "日期"
    }
}
