import SwiftData
import XCTest
@testable import Gridnote

@MainActor
final class ReaderViewModelTests: XCTestCase {
    func testLoadsTXTAndRestoresSavedProgress() throws {
        let sourceURL = try makeTemporaryTXT()
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let record = try BookRepository(context: context).insert(
            metadata: BookMetadata(title: "Reader Fixture", sourceFilename: sourceURL.lastPathComponent),
            sourcePath: sourceURL.path,
            format: .txt
        )

        let firstViewModel = ReaderViewModel(context: context)
        firstViewModel.load(bookID: record.id)
        XCTAssertEqual(firstViewModel.currentText, "First paragraph")

        firstViewModel.nextBlock()
        XCTAssertEqual(firstViewModel.currentText, "Second paragraph")

        let restoredViewModel = ReaderViewModel(context: context)
        restoredViewModel.load(bookID: record.id)
        XCTAssertEqual(restoredViewModel.currentText, "Second paragraph")
        XCTAssertEqual(restoredViewModel.progressText, "Paragraph 2 of 2")
    }

    func testFontSizePersistsToSettings() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let viewModel = ReaderViewModel(context: context)

        viewModel.updateFontSize(22)

        let settings = try AppSettingsRepository(context: context).fetchOrCreate()
        XCTAssertEqual(settings.standardReaderFontSize, 22)
    }

    func testReloadSettingsAppliesPersistedReaderPreferences() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let viewModel = ReaderViewModel(context: context)

        try AppSettingsRepository(context: context).updateReader(fontSize: 24, lineHeight: 13, theme: "dark")
        viewModel.reloadSettings()

        XCTAssertEqual(viewModel.fontSize, 24)
        XCTAssertEqual(viewModel.lineHeight, 13)
        XCTAssertEqual(viewModel.theme, "dark")
    }

    func testLoadsEPUBThroughCanonicalReader() throws {
        let sourceURL = try EPUBFixture.writeTemporaryFile()
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let record = try BookRepository(context: context).insert(metadata: .init(title: "Fallback", sourceFilename: sourceURL.lastPathComponent), sourcePath: sourceURL.path, format: .epub)
        let viewModel = ReaderViewModel(context: context)
        viewModel.load(bookID: record.id)
        XCTAssertEqual(viewModel.title, "Fixture Book")
        XCTAssertEqual(viewModel.currentText, "Chapter One")
        viewModel.nextBlock()
        XCTAssertEqual(viewModel.currentText, "First paragraph.")
    }

    private func makeTemporaryTXT() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-reader-\(UUID().uuidString)")
            .appendingPathExtension("txt")
        try Data("First paragraph\n\nSecond paragraph".utf8).write(to: url)
        return url
    }
}
