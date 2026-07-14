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

    // Only the deduplicated public model names originate from the reference workbook.
    // Every identifier, specification, date, status, amount, and relationship is synthetic.
    static let demoModelCatalog = [
        "红米 K80",
        "红米 K80 至尊版",
        "红米 K80 Pro",
        "红米 K90",
        "红米 K90 Max",
        "红米 K90 Pro Max",
        "红米 Note 15 Pro",
        "红米 Note 15 Pro +",
        "红米 Note15",
        "红米 Turbo 4",
        "红米 Turbo 4 Pro",
        "红米 Turbo 5 Max",
        "红米 Turbo5",
        "红米 Turbo5 max",
        "红米Note 14",
        "红米Note15",
        "红米Turbo 4 pro",
        "华为 畅享 80",
        "华为 Mate 70 Air",
        "华为 Mate 80",
        "华为 Mate 80 Pro",
        "华为 Mate 80 Pro Max",
        "华为 Mate X6",
        "华为 mate70 Pro 优享版",
        "华为 nova 14",
        "华为 nova 14 Pro",
        "华为 nova 14 Ultra",
        "华为 nova 15",
        "华为 nova 15 Pro",
        "华为 nova 15 Ultra",
        "华为 nova 16",
        "华为 nova 16 Pro",
        "华为 Pura 80",
        "华为 Pura 80 Pro",
        "华为 Pura 80 Pro+",
        "华为 Pura 80 Ultra",
        "华为 Pura 90",
        "华为 Pura 90 Pro",
        "华为 Pura 90 Pro Max",
        "华为 Pura X",
        "华为畅享 70x活力版",
        "华为畅享 80",
        "华为畅享 90 Plus",
        "华为畅享 90 Pro Max",
        "华为Mate 70",
        "华为mate70",
        "华为Mate70 Pro",
        "华为Mate70 Pro+",
        "华为mate70Pro",
        "华为mate70Pro+",
        "华为nova 14",
        "华为nova Flip",
        "华为novaFlip",
        "荣耀 400",
        "荣耀 400 pro",
        "荣耀 500",
        "荣耀 500 Pro",
        "荣耀 GT",
        "荣耀 Magic 7",
        "荣耀 Magic V Flip2",
        "荣耀 Magic V5",
        "荣耀 Magic8",
        "荣耀 Magic8 pro",
        "荣耀 Magic8 Pro",
        "荣耀 Magic8 Pro Air",
        "荣耀 Power",
        "荣耀 X70i",
        "荣耀400 Pro",
        "荣耀500",
        "荣耀500 Pro",
        "荣耀600 超级版",
        "荣耀600 元气版",
        "荣耀600 Pro",
        "荣耀GT",
        "荣耀Magic V Flip2",
        "荣耀Magic V5",
        "荣耀Magic7",
        "荣耀Magic7 Pro",
        "荣耀Power",
        "荣耀X60",
        "荣耀X60 GT",
        "三星 Galaxy S25",
        "三星 Galaxy S25 Ultra",
        "三星 Galaxy S26 Ultra",
        "三星 Galaxy Z Flip7",
        "三星 Galaxy Z Flip7 FE",
        "三星 Galaxy Z Fold7",
        "三星A56",
        "三星Fold7",
        "小米 15",
        "小米 15 Pro",
        "小米 17",
        "小米 17 Max",
        "小米 17 Pro",
        "小米 17 Pro Max",
        "小米 17 Ultra",
        "小米 17T",
        "小米15",
        "小米15 Pro",
        "小米15 Ultra",
        "小米17",
        "小米17Pro",
        "小米17Pro Max",
        "小米17Ultra",
        "小米Civi 5 Pro",
        "一加 13T",
        "一加 15",
        "一加 15T",
        "一加 Ace 6",
        "一加 ACE 6",
        "一加 Ace 6 至尊版",
        "一加 Ace 6T",
        "一加 Turbo 6",
        "一加 Turbo 6V",
        "一加 Turbo 6X",
        "一加 Turbo 6X Pro",
        "一加ACE 6至尊版",
        "一加ACE 6T",
        "真我 15",
        "真我 15 Pro",
        "真我 15T",
        "真我 GT7 Pro 竞速版",
        "真我 GT7 Pro竞速",
        "真我 GT8",
        "真我 GT8 Pro",
        "真我 Neo8",
        "真我15",
        "Galaxy A57",
        "Galaxy S25",
        "Galaxy S25 Ultra",
        "Galaxy S26",
        "Galaxy S26 Ultra",
        "Galaxy S26+",
        "HUAWEI Pura 80 Pro",
        "HUAWEI Pura 80 Pro+",
        "HUAWEI Pura 80 Ultra",
        "HUAWEI Pura X",
        "iQOO 15",
        "iQOO 15 Ultra",
        "iQOO 15T",
        "iQOO Neo 11",
        "iQOO Neo11",
        "iQOO Z10 Turbo",
        "iQOO Z10 Turbo Pro",
        "IQOO Z11",
        "IQOO Z11 Turbo",
        "iQOO Z11x",
        "iQOO Z11X",
        "K13 Turbo",
        "K13 Turbo Pro",
        "mate70pro 优享版",
        "nova 14 Ultra",
        "OPPO A5",
        "OPPO A5 活力版",
        "OPPO A6",
        "OPPO A6 GT",
        "OPPO A6 Pro",
        "OPPO A6s Pro",
        "OPPO A6S Pro",
        "OPPO Find N5",
        "OPPO Find X8",
        "OPPO Find X8 Pro",
        "OPPO Find X8 Ultra",
        "OPPO Find X8s",
        "OPPO Find X8s+",
        "OPPO Find X9",
        "OPPO Find X9 Pro",
        "OPPO Find X9s Pro",
        "OPPO Find X9S Pro",
        "OPPO K12s",
        "OPPO K13 Turbo",
        "OPPO K13 Turbo Pro",
        "OPPO K13S",
        "OPPO K13X",
        "OPPO K15 Pro",
        "OPPO K15 Pro+",
        "OPPO reno 13",
        "OPPO Reno 15",
        "OPPO Reno 15 Pro",
        "OPPO Reno 15c",
        "OPPO Reno14",
        "OPPO Reno14 Pro",
        "OPPO Reno15",
        "OPPO Reno15 Pro",
        "OPPO Reno16",
        "OPPO Reno16 Pro",
        "REDMI K80",
        "REDMI K80 Pro",
        "REDMI K90",
        "REDMI K90 Max",
        "REDMI K90 Pro Max",
        "Redmi Note 14",
        "Redmi Note 14 Pro",
        "Redmi Note 14 Pro+",
        "REDMI Note 15 Pro",
        "vivo iQOO Z10 Turbo Pro",
        "vivo iQOO Z10x",
        "vivo S30",
        "vivo S30 Pro mini",
        "vivo S30Pro Mini",
        "vivo S50",
        "VIVO S50",
        "VIVO S50 Pro mini",
        "vivo S50Pro Mini",
        "vivo S60",
        "vivo S60 元气版",
        "vivo x Fold 5",
        "vivo X200 Pro",
        "vivo X200 Pro mini",
        "vivo x200 ultra",
        "vivo x200s",
        "VIVO X200S",
        "vivo X300",
        "VIVO X300",
        "vivo X300 Pro",
        "VIVO X300 Pro",
        "vivo X300 Ultra",
        "vivo X300s",
        "vivo xfold 5",
        "vivo Y300 GT",
        "vivo Y300 Pro",
        "vivo Y300 Pro+",
        "vivo Y300 t",
        "vivo Y300t",
        "vivo Y50",
        "vivo Y500",
        "vivo Y500 Pro",
        "vivo Y60",
        "vivo Y600 Pro",
        "Y300 Pro+",
        "Y500",
    ]

    static var defaultOperations: OfficeGridSnapshot {
        let headers = [
            "演示订单号", "演示设备编号", "品牌", "机型", "演示规格", "演示颜色",
            "租期（月）", "设备成色", "申请日期", "审核状态", "签约状态", "仓配节点",
            "发货状态", "月租金（演示）", "保证金（演示）", "风险等级", "处理人代码", "处理备注"
        ]
        let rows = demoRecords(seed: 0x4752_4944_4E4F_5445, modelOffset: 0).map { record in
            [
                record.orderID, record.deviceID, record.brand, record.model, record.specification,
                record.color, "\(record.term)", record.condition, record.applicationDate,
                record.reviewState, record.contractState, record.warehouse, record.shippingState,
                "¥\(record.monthlyRent)", "¥\(record.deposit)", record.riskLevel,
                record.operatorCode, record.note
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
        let headers = [
            "演示订单号", "机型", "演示规格", "申请日期", "资料状态", "审核状态",
            "风险等级", "预授权", "签约状态", "仓配节点", "备货状态", "物流状态",
            "预计送达", "租期（月）", "月租金（演示）", "保证金（演示）", "处理人代码", "处理备注"
        ]
        let rows = demoRecords(seed: 0x4F52_4445_5253_3032, modelOffset: 37).map { record in
            [
                record.orderID, record.model, record.specification, record.applicationDate,
                record.documentState, record.reviewState, record.riskLevel, record.authorizationState,
                record.contractState, record.warehouse, record.stockState, record.shippingState,
                record.expectedDate, "\(record.term)", "¥\(record.monthlyRent)",
                "¥\(record.deposit)", record.operatorCode, record.note
            ]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    static var inventoryFulfillment: OfficeGridSnapshot {
        let headers = [
            "演示设备编号", "机型", "演示规格", "演示颜色", "仓配节点", "演示库位",
            "库存状态", "检测状态", "电池状态", "屏幕状态", "配件状态", "入库日期",
            "预计出库", "关联演示订单", "配送状态", "周转天数", "处理人代码", "处理备注"
        ]
        let records = demoRecords(seed: 0x5741_5245_484F_5553, modelOffset: 79)
        let rows = records.enumerated().map { index, record in
            [
                record.deviceID, record.model, record.specification, record.color, record.warehouse,
                String(format: "A-%02d-%02d", index % 8 + 1, index % 24 + 1),
                record.stockState, record.inspectionState, record.batteryState, record.screenState,
                record.accessoryState, record.applicationDate, record.expectedDate, record.orderID,
                record.shippingState, "\(9 + index % 27)", record.operatorCode, record.note
            ]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    static var deviceLedger: OfficeGridSnapshot {
        let headers = [
            "演示设备编号", "品牌", "机型", "演示规格", "演示颜色", "设备成色",
            "当前状态", "租期（月）", "启用日期", "最近检查", "电池状态", "屏幕状态",
            "外观等级", "配件状态", "预计回收", "风险等级", "处理人代码", "处理备注"
        ]
        let records = demoRecords(seed: 0x4C45_4447_4552_3034, modelOffset: 121)
        let rows = records.map { record in
            [
                record.deviceID, record.brand, record.model, record.specification, record.color,
                record.condition, record.deviceState, "\(record.term)", record.applicationDate,
                record.inspectionDate, record.batteryState, record.screenState, record.appearanceGrade,
                record.accessoryState, record.expectedDate, record.riskLevel, record.operatorCode,
                record.note
            ]
        }
        return denseSnapshot(headers: headers, rows: rows)
    }

    private static func demoRecords(seed: UInt64, modelOffset: Int) -> [DemoRentalRecord] {
        var random = DemoRandom(seed: seed)
        let specifications = [
            "6GB + 128GB", "8GB + 128GB", "8GB + 256GB",
            "12GB + 256GB", "12GB + 512GB", "16GB + 512GB"
        ]
        let colors = ["曜石黑", "星云蓝", "月光银", "云雾白", "深空灰", "青岚绿"]
        let terms = [3, 6, 12, 18, 24]
        let conditions = ["全新", "准新", "轻微使用"]
        let documentStates = ["资料齐全", "等待补充", "复核完成"]
        let reviewStates = ["待复核", "审核中", "已通过", "补充资料"]
        let authorizationStates = ["待调用", "处理中", "已完成"]
        let contractStates = ["待签约", "签约中", "已签约"]
        let warehouses = ["华东演示仓", "华南演示仓", "华中演示仓", "西南演示仓"]
        let stockStates = ["待备货", "备货中", "已锁定", "可出库"]
        let shippingStates = ["待发出", "配送中", "已签收", "待调度"]
        let riskLevels = ["演示低", "演示低", "演示中", "待复核"]
        let notes = ["常规跟进", "等待资料", "仓配核对", "签约确认", "设备检查", "进度正常"]
        let deviceStates = ["可用", "租赁中", "待检查", "待回收"]
        let inspectionStates = ["检测通过", "待检测", "复检中"]
        let screenStates = ["良好", "轻微痕迹", "待复检"]
        let accessoryStates = ["齐全", "待补充", "核对中"]
        let appearanceGrades = ["A", "A-", "B+", "B"]

        return (0..<(rowCount - 1)).map { index in
            let model = demoModelCatalog[(index * 73 + modelOffset) % demoModelCatalog.count]
            let orderID = "GN-\(random.code(length: 4))-\(random.code(length: 6))\(String(format: "%02X", index))"
            let deviceID = "DEV-\(random.code(length: 10))"
            let applicationDay = 1 + random.integer(upperBound: 28)
            let expectedDay = 1 + random.integer(upperBound: 28)
            let inspectionDay = 1 + random.integer(upperBound: 28)
            return DemoRentalRecord(
                orderID: orderID,
                deviceID: deviceID,
                brand: brand(for: model),
                model: model,
                specification: random.element(from: specifications),
                color: random.element(from: colors),
                term: random.element(from: terms),
                condition: random.element(from: conditions),
                applicationDate: String(format: "2026-07-%02d", applicationDay),
                expectedDate: String(format: "2026-08-%02d", expectedDay),
                inspectionDate: String(format: "2026-07-%02d", inspectionDay),
                documentState: random.element(from: documentStates),
                reviewState: random.element(from: reviewStates),
                authorizationState: random.element(from: authorizationStates),
                contractState: random.element(from: contractStates),
                warehouse: random.element(from: warehouses),
                stockState: random.element(from: stockStates),
                shippingState: random.element(from: shippingStates),
                monthlyRent: 129 + random.integer(upperBound: 68) * 10,
                deposit: 500 + random.integer(upperBound: 31) * 100,
                riskLevel: random.element(from: riskLevels),
                operatorCode: "OP-\(random.code(length: 4))",
                note: random.element(from: notes),
                deviceState: random.element(from: deviceStates),
                inspectionState: random.element(from: inspectionStates),
                batteryState: "\(83 + random.integer(upperBound: 16))%",
                screenState: random.element(from: screenStates),
                accessoryState: random.element(from: accessoryStates),
                appearanceGrade: random.element(from: appearanceGrades)
            )
        }
    }

    private static func denseSnapshot(headers: [String], rows: [[String]]) -> OfficeGridSnapshot {
        precondition(headers.count == columnCount)
        var snapshot = OfficeGridSnapshot(values: [:])
        for (rowIndex, row) in ([headers] + rows).prefix(rowCount).enumerated() {
            for columnIndex in 0..<columnCount {
                snapshot[OfficeCellCoordinate(row: rowIndex, column: columnIndex)] =
                    row.indices.contains(columnIndex) ? row[columnIndex] : "-"
            }
        }
        return snapshot
    }

    private static func brand(for model: String) -> String {
        let value = model.lowercased()
        let mappings: [(needle: String, brand: String)] = [
            ("iphone", "Apple"), ("ipad", "Apple"), ("苹果", "Apple"),
            ("华为", "华为"), ("huawei", "华为"), ("荣耀", "荣耀"),
            ("红米", "Redmi"), ("redmi", "Redmi"), ("小米", "小米"),
            ("iqoo", "iQOO"), ("vivo", "vivo"), ("oppo", "OPPO"),
            ("一加", "一加"), ("oneplus", "一加"), ("realme", "realme"),
            ("真我", "realme"), ("三星", "三星"), ("samsung", "三星"),
            ("魅族", "魅族"), ("努比亚", "努比亚"), ("motorola", "Motorola")
        ]
        return mappings.first(where: { value.contains($0.needle) })?.brand
            ?? model.split(separator: " ").first.map(String.init)
            ?? "其他"
    }

    var isLegacyOperationsTemplate: Bool {
        let firstHeader = self[OfficeCellCoordinate(row: 0, column: 0)]
        let modelHeader = self[OfficeCellCoordinate(row: 0, column: 4)]
        return ["Date", "日期", "演示日期", "统计周期"].contains(firstHeader)
            || ["设备型号", "商品简称（机型）"].contains(modelHeader)
    }
}

private struct DemoRentalRecord {
    let orderID: String
    let deviceID: String
    let brand: String
    let model: String
    let specification: String
    let color: String
    let term: Int
    let condition: String
    let applicationDate: String
    let expectedDate: String
    let inspectionDate: String
    let documentState: String
    let reviewState: String
    let authorizationState: String
    let contractState: String
    let warehouse: String
    let stockState: String
    let shippingState: String
    let monthlyRent: Int
    let deposit: Int
    let riskLevel: String
    let operatorCode: String
    let note: String
    let deviceState: String
    let inspectionState: String
    let batteryState: String
    let screenState: String
    let accessoryState: String
    let appearanceGrade: String
}

private struct DemoRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xA5A5_A5A5_A5A5_A5A5 : seed
    }

    mutating func integer(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        return Int(next() % UInt64(upperBound))
    }

    mutating func element<T>(from values: [T]) -> T {
        values[integer(upperBound: values.count)]
    }

    mutating func code(length: Int) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).map { _ in alphabet[integer(upperBound: alphabet.count)] })
    }

    private mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
