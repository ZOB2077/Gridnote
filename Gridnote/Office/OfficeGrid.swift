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

    static var defaultOperations: OfficeGridSnapshot {
        var snapshot = OfficeGridSnapshot(values: [:])
        let rows = [
            ["统计周期", "一级订单归属", "商户类型", "小程序", "商品简称（机型）", "下单数", "前置通过订单数", "前置通过率", "预授权调用订单数", "预授权签约订单数", "预授权签约率", "全免订单数", "全免率", "进入后置订单数", "可分流订单数", "分流成功订单数", "后置通过订单数", "后置通过率"],
            ["2026-07-09", "02_租物", "商户", "优品go", "一加 Ace 6", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "优品go", "华为 Mate 80", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "优品go", "华为 Pura 80 Pro", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "优品go", "红米 K90", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "优品租", "vivo iQOO Z10x", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "租手机青年优品", "OPPO Find X9 Pro", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "租手机青年优品", "OPPO K13 Turbo", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "租手机青年优品", "一加 15", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "商户", "租手机青年优品", "小米17Pro Max", "2", "2", "100.00%", "2", "2", "100.00%", "2", "100.00%", "2", "2", "2", "0", "0.00%"],
            ["2026-07-09", "02_租物", "商户", "青友租", "一加 15", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "1", "1", "1", "100.00%"],
            ["2026-07-09", "02_租物", "自营", "优品go", "Galaxy S26+", "1", "1", "100.00%", "0", "0", "--", "0", "--", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "HUAWEI Pura X", "1", "1", "100.00%", "0", "0", "--", "0", "--", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "IQOO Z11 Turbo", "1", "1", "100.00%", "0", "0", "--", "0", "--", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "OPPO K12s", "1", "1", "100.00%", "1", "1", "100.00%", "0", "0.00%", "1", "1", "0", "0", "0.00%"],
            ["2026-07-09", "02_租物", "自营", "优品go", "OPPO Reno14", "4", "4", "100.00%", "3", "1", "33.33%", "0", "0.00%", "1", "1", "0", "0", "0.00%"],
            ["2026-07-09", "02_租物", "自营", "优品go", "OPPO Reno16", "4", "4", "100.00%", "0", "0", "--", "0", "--", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "REDMI K90", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "1", "0", "0", "0", "0.00%"],
            ["2026-07-09", "02_租物", "自营", "优品go", "REDMI K90 Pro Max", "1", "1", "100.00%", "1", "1", "100.00%", "1", "100.00%", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "VIVO X200S", "1", "1", "100.00%", "0", "0", "--", "0", "--", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "iQOO 15", "1", "1", "100.00%", "0", "0", "--", "0", "--", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "iQOO 15 Ultra", "1", "1", "100.00%", "1", "0", "0.00%", "0", "0.00%", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "iQOO 15T", "4", "4", "100.00%", "3", "2", "66.67%", "2", "66.67%", "2", "2", "1", "1", "50.00%"],
            ["2026-07-09", "02_租物", "自营", "优品go", "iQOO Neo11", "1", "1", "100.00%", "0", "0", "--", "0", "--", "0", "0", "0", "0", "--"],
            ["2026-07-09", "02_租物", "自营", "优品go", "vivo S60", "6", "6", "100.00%", "4", "4", "100.00%", "4", "100.00%", "4", "4", "2", "2", "50.00%"]
        ]
        for (rowIndex, row) in rows.enumerated() {
            for (columnIndex, value) in row.enumerated() {
                snapshot[OfficeCellCoordinate(row: rowIndex, column: columnIndex)] = value
            }
        }
        return snapshot
    }

    static func snapshot(for template: OfficeTemplateFamily) -> OfficeGridSnapshot {
        switch template {
        case .operations:
            defaultOperations
        case .projectTracking:
            channelConversion
        case .budget:
            inventoryFulfillment
        case .notes:
            deviceLedger
        }
    }

    static var channelConversion: OfficeGridSnapshot {
        let headers = ["统计周期", "活动名称", "区域", "小程序", "商品简称（机型）", "曝光量", "访问量", "加购量", "下单数", "支付数", "支付转化率", "前置通过", "预授权签约", "签约率", "进入后置", "后置通过", "最终发货", "备注"]
        let models = ["iPhone 17", "华为 Mate 80", "vivo X200S", "OPPO Reno16", "一加 15", "小米 17 Pro", "荣耀 Magic8", "iQOO 15", "三星 S26", "REDMI K90", "华为 Pura 80", "OPPO Find X9", "vivo S60", "荣耀 X70", "iPhone 16 Pro", "一加 Ace 6", "小米 Civi 6", "华为 nova 15", "iQOO Neo11", "OPPO K13", "三星 A77", "荣耀 500", "REDMI Note 15", "vivo Y300"]
        let regions = ["华东", "华南", "华北", "西南"]
        let channels = ["优品go", "租手机青年优品", "青友租", "优品租"]
        let rows = models.enumerated().map { index, model in
            let exposure = 260 + index * 37
            let visits = 74 + index * 9
            let orders = 4 + index % 7
            let paid = max(1, orders - index % 3)
            return ["2026-07-13", "暑期换新", regions[index % regions.count], channels[index % channels.count], model, "\(exposure)", "\(visits)", "\(orders + 6)", "\(orders)", "\(paid)", String(format: "%.2f%%", Double(paid) / Double(visits) * 100), "\(max(1, paid - 1))", "\(max(1, paid - 1))", String(format: "%.2f%%", Double(max(1, paid - 1)) / Double(paid) * 100), "\(max(1, paid - 2))", "\(max(0, paid - 2))", "\(max(0, paid - 2))", index.isMultiple(of: 5) ? "重点观察" : "正常"]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    static var inventoryFulfillment: OfficeGridSnapshot {
        let headers = ["统计日期", "仓库", "城市", "渠道", "商品简称（机型）", "在租台数", "可租库存", "调拨中", "近7日下单", "待审核", "履约中", "待发货", "已签收", "回收中", "签收率", "周转天数", "库存预警", "处理建议"]
        let models = ["iPhone 17", "华为 Mate 80", "vivo X200S", "OPPO Reno16", "一加 15", "小米 17 Pro", "荣耀 Magic8", "iQOO 15", "三星 S26", "REDMI K90", "华为 Pura 80", "OPPO Find X9", "vivo S60", "荣耀 X70", "iPhone 16 Pro", "一加 Ace 6", "小米 Civi 6", "华为 nova 15", "iQOO Neo11", "OPPO K13", "三星 A77", "荣耀 500", "REDMI Note 15", "vivo Y300"]
        let cities = ["上海", "广州", "北京", "成都", "杭州", "武汉"]
        let rows = models.enumerated().map { index, model in
            let rentable = 8 + index % 18
            let pending = 1 + index % 5
            let delivering = 2 + index % 6
            let signed = delivering + 4
            return ["2026-07-13", index.isMultiple(of: 2) ? "华东中心仓" : "华南中心仓", cities[index % cities.count], index.isMultiple(of: 3) ? "优品go" : "青年优品", model, "\(42 + index * 3)", "\(rentable)", "\(index % 4)", "\(6 + index % 8)", "\(pending)", "\(delivering)", "\(max(1, pending - 1))", "\(signed)", "\(index % 3)", String(format: "%.2f%%", Double(signed) / Double(signed + pending) * 100), "\(14 + index % 12)", rentable < 12 ? "补货" : "充足", rentable < 12 ? "优先调拨" : "正常跟进"]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    static var deviceLedger: OfficeGridSnapshot {
        let headers = ["登记日期", "资产编号", "区域", "门店", "商品简称（机型）", "设备状态", "租约状态", "本期租金", "押金", "使用时长", "最近巡检", "电池健康", "屏幕状态", "外观等级", "配件齐全", "回收预计", "风险等级", "处理备注"]
        let models = ["iPhone 17", "华为 Mate 80", "vivo X200S", "OPPO Reno16", "一加 15", "小米 17 Pro", "荣耀 Magic8", "iQOO 15", "三星 S26", "REDMI K90", "华为 Pura 80", "OPPO Find X9", "vivo S60", "荣耀 X70", "iPhone 16 Pro", "一加 Ace 6", "小米 Civi 6", "华为 nova 15", "iQOO Neo11", "OPPO K13", "三星 A77", "荣耀 500", "REDMI Note 15", "vivo Y300"]
        let rows = models.enumerated().map { index, model in
            let days = 18 + index * 3
            return ["2026-07-13", String(format: "SH-%04d", 2100 + index), index.isMultiple(of: 2) ? "华东" : "华南", index.isMultiple(of: 3) ? "直营店" : "合作门店", model, index.isMultiple(of: 6) ? "待检" : "在库", index.isMultiple(of: 4) ? "即将到期" : "履约中", "¥\(199 + index * 30)", "¥\(699 + index * 50)", "\(days) 天", "2026-07-\(String(format: "%02d", 4 + index % 9))", "\(83 + index % 15)%", index.isMultiple(of: 7) ? "轻微划痕" : "良好", index.isMultiple(of: 5) ? "B+" : "A", index.isMultiple(of: 8) ? "缺充电线" : "齐全", "2026-08-\(String(format: "%02d", 5 + index % 20))", index.isMultiple(of: 6) ? "中" : "低", index.isMultiple(of: 6) ? "安排巡检" : "正常"]
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

    /// Original order-detail templates are replaced by the reference-style operations sheet.
    var isLegacyOperationsTemplate: Bool {
        let firstHeader = self[OfficeCellCoordinate(row: 0, column: 0)]
        return firstHeader == "Date" || firstHeader == "日期"
    }
}
