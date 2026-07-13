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

    func testDefaultOperationsFillsEveryVisibleCellWithRentalData() {
        let snapshot = OfficeGridSnapshot.defaultOperations

        for row in 0..<OfficeGridSnapshot.rowCount {
            for column in 0..<OfficeGridSnapshot.columnCount {
                XCTAssertFalse(snapshot[OfficeCellCoordinate(row: row, column: column)].isEmpty)
            }
        }
        XCTAssertEqual(snapshot[OfficeCellCoordinate(row: 0, column: 4)], "商品简称（机型）")
        XCTAssertEqual(snapshot[OfficeCellCoordinate(row: 1, column: 4)], "一加 Ace 6")
        XCTAssertEqual(snapshot[OfficeCellCoordinate(row: 1, column: 7)], "100.00%")
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

        OfficeFormulaMaskSettings.save(enabled: false, delay: 100, to: defaults)
        XCTAssertFalse(OfficeFormulaMaskSettings.isEnabled(in: defaults))
        XCTAssertEqual(OfficeFormulaMaskSettings.delay(in: defaults), OfficeFormulaMaskSettings.delayRange.upperBound)
    }
}
