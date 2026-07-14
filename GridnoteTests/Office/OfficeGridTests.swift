import SwiftData
import XCTest
@testable import Gridnote

@MainActor
final class OfficeGridTests: XCTestCase {
    func testCoordinateNamesAndSnapshotRoundTrip() throws {
        XCTAssertEqual(OfficeCellCoordinate(row: 0, column: 0).name, "A1")
        XCTAssertEqual(OfficeCellCoordinate(row: 4, column: 26).name, "AA5")
        var snapshot = OfficeGridSnapshot(values: [:])
        snapshot[OfficeCellCoordinate(row: 2, column: 3)] = "42"
        let data = try JSONEncoder().encode(snapshot)
        XCTAssertEqual(try JSONDecoder().decode(OfficeGridSnapshot.self, from: data), snapshot)
    }

    func testDefaultOperationsFillsEveryVisibleCellWithSyntheticData() {
        let snapshot = OfficeGridSnapshot.defaultOperations

        for row in 0..<OfficeGridSnapshot.rowCount {
            for column in 0..<OfficeGridSnapshot.columnCount {
                XCTAssertFalse(snapshot[OfficeCellCoordinate(row: row, column: column)].isEmpty)
            }
        }
        XCTAssertEqual(snapshot[OfficeCellCoordinate(row: 0, column: 0)], "演示订单号")
        XCTAssertTrue(snapshot[OfficeCellCoordinate(row: 1, column: 0)].hasPrefix("GN-"))
        XCTAssertTrue(OfficeGridSnapshot.demoModelCatalog.contains(snapshot[OfficeCellCoordinate(row: 1, column: 3)]))
    }

    func testEveryDisguiseTemplateFillsTheVisibleSyntheticGrid() {
        for template in OfficeTemplateFamily.allCases {
            let snapshot = OfficeGridSnapshot.snapshot(for: template)
            for row in 0..<OfficeGridSnapshot.rowCount {
                for column in 0..<OfficeGridSnapshot.columnCount {
                    XCTAssertFalse(snapshot[OfficeCellCoordinate(row: row, column: column)].isEmpty, "\(template.rawValue) has an empty \(row),\(column)")
                }
            }
        }
        XCTAssertEqual(OfficeGridSnapshot.channelConversion[OfficeCellCoordinate(row: 0, column: 4)], "资料状态")
        XCTAssertEqual(OfficeGridSnapshot.inventoryFulfillment[OfficeCellCoordinate(row: 0, column: 6)], "库存状态")
    }

    func testDemoOrdersAreDeterministicUniqueAndContainNoBusinessReportHeaders() {
        let first = OfficeGridSnapshot.defaultOperations
        let second = OfficeGridSnapshot.defaultOperations
        XCTAssertEqual(first, second)

        let orderIDs = (1..<OfficeGridSnapshot.rowCount).map {
            first[OfficeCellCoordinate(row: $0, column: 0)]
        }
        XCTAssertEqual(Set(orderIDs).count, orderIDs.count)
        XCTAssertTrue(orderIDs.allSatisfy { $0.range(of: #"^GN-[A-Z2-9]{4}-[A-Z0-9]{8}$"#, options: .regularExpression) != nil })

        let forbiddenFragments = ["一级订单", "商户类型", "GMV", "毛利", "转化率"]
        for template in OfficeTemplateFamily.allCases {
            let snapshot = OfficeGridSnapshot.snapshot(for: template)
            for value in snapshot.values.values {
                XCTAssertFalse(forbiddenFragments.contains(where: value.contains))
            }
        }
    }

    func testModelCatalogIsDeduplicated() {
        XCTAssertFalse(OfficeGridSnapshot.demoModelCatalog.isEmpty)
        XCTAssertEqual(Set(OfficeGridSnapshot.demoModelCatalog).count, OfficeGridSnapshot.demoModelCatalog.count)
    }

    func testOldRentalGridIsRecognizedForReferenceStyleMigration() {
        var legacy = OfficeGridSnapshot(values: [:])
        legacy[OfficeCellCoordinate(row: 0, column: 0)] = "日期"
        XCTAssertTrue(legacy.isLegacyOperationsTemplate)
    }

    func testOfficeSheetPersistsGridSelectionAndSheetName() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let repository = OfficeSheetRepository(context: context)
        let record = try repository.fetchOrCreate(bookID: nil)
        var snapshot = repository.snapshot(from: record)
        let coordinate = OfficeCellCoordinate(row: 3, column: 2)
        snapshot[coordinate] = "Persisted value"
        try repository.save(snapshot: snapshot, selected: coordinate, sheetName: "Weekly Plan", to: record)

        let reloaded = try repository.fetchOrCreate(bookID: nil)
        XCTAssertEqual(repository.snapshot(from: reloaded)[coordinate], "Persisted value")
        XCTAssertEqual(reloaded.selectedRow, 3)
        XCTAssertEqual(reloaded.selectedColumn, 2)
        XCTAssertEqual(reloaded.activeSheetName, "Weekly Plan")
    }

    func testApplyingDisguiseTemplatePersistsItsDataAndSheetName() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let repository = OfficeSheetRepository(context: context)
        let record = try repository.fetchOrCreate(bookID: nil)

        let applied = try repository.apply(template: .budget, to: record)
        let reloaded = try repository.fetchOrCreate(bookID: nil)

        XCTAssertEqual(reloaded.templateFamilyRawValue, OfficeTemplateFamily.budget.rawValue)
        XCTAssertEqual(reloaded.activeSheetName, OfficeTemplateFamily.budget.defaultSheetName)
        XCTAssertEqual(repository.snapshot(from: reloaded), applied)
        XCTAssertEqual(applied[OfficeCellCoordinate(row: 0, column: 6)], "库存状态")
    }

    func testExcerptSearchWrapsInBothDirections() {
        let blocks = [
            TextBlock(id: "one", text: "首段租赁日报"),
            TextBlock(id: "two", text: "中段包含目标词"),
            TextBlock(id: "three", text: "末段目标词再次出现")
        ]

        XCTAssertEqual(
            OfficeExcerptSearch.matchingBlockIndex(in: blocks, query: "目标词", currentIndex: 0, direction: .next),
            1
        )
        XCTAssertEqual(
            OfficeExcerptSearch.matchingBlockIndex(in: blocks, query: "目标词", currentIndex: 0, direction: .previous),
            2
        )
        XCTAssertNil(
            OfficeExcerptSearch.matchingBlockIndex(in: blocks, query: "不存在", currentIndex: 0, direction: .next)
        )
    }

    func testFormulaMaskSettingsDefaultAndClampValues() {
        let suiteName = "gridnote-office-privacy-\(UUID().uuidString)"
        let defaults = try! XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(OfficeFormulaMaskSettings.isEnabled(in: defaults))
        XCTAssertEqual(OfficeFormulaMaskSettings.delay(in: defaults), OfficeFormulaMaskSettings.defaultDelay)

        OfficeFormulaMaskSettings.save(enabled: false, delay: 100, lineCount: 100, masksOnPointerExit: false, pointerExitDelay: 100, to: defaults)
        XCTAssertFalse(OfficeFormulaMaskSettings.isEnabled(in: defaults))
        XCTAssertEqual(OfficeFormulaMaskSettings.delay(in: defaults), OfficeFormulaMaskSettings.delayRange.upperBound)
        XCTAssertEqual(OfficeFormulaMaskSettings.lineCount(in: defaults), OfficeFormulaMaskSettings.lineCountRange.upperBound)
        XCTAssertFalse(OfficeFormulaMaskSettings.masksOnPointerExit(in: defaults))
        XCTAssertEqual(OfficeFormulaMaskSettings.pointerExitDelay(in: defaults), OfficeFormulaMaskSettings.pointerExitDelayRange.upperBound)
    }
}
