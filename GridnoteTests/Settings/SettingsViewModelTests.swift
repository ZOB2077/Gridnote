import SwiftData
import XCTest
@testable import Gridnote

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testAliasAndReaderSettingsPersist() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let book = try BookRepository(context: context).insert(metadata: .init(title: "Actual Novel"), sourcePath: "/tmp/book.txt", format: .txt)
        let viewModel = SettingsViewModel(context: context, bookID: book.id)
        viewModel.load()
        viewModel.aliasTitle = "Quarterly Review"
        viewModel.workbookTitle = "Q3 Operations.xlsx"
        viewModel.sheetName = "Status"
        viewModel.fontSize = 21
        viewModel.lineHeight = 11
        viewModel.theme = "paper"
        viewModel.autoSwitch = true
        viewModel.saveAlias()
        viewModel.saveReadingSettings()
        viewModel.saveOfficeSettings()

        let alias = try XCTUnwrap(AliasProfileRepository(context: context).fetch(bookID: book.id))
        XCTAssertEqual(alias.workbookTitle, "Q3 Operations.xlsx")
        XCTAssertEqual(alias.sheetName, "Status")
        let settings = try AppSettingsRepository(context: context).fetchOrCreate()
        XCTAssertEqual(settings.standardReaderFontSize, 21)
        XCTAssertEqual(settings.standardReaderLineHeight, 11)
        XCTAssertEqual(settings.readerThemeRawValue, "paper")
        XCTAssertTrue(settings.resignToOfficeOnDeactivate)
    }
}
