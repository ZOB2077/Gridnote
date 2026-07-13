import SwiftData
import XCTest
@testable import Gridnote

@MainActor
final class LibraryRepositoryTests: XCTestCase {
    func testAliasIsPreferredAndSearchMatchesAliasOrActualTitle() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let book = try BookRepository(context: context).insert(metadata: .init(title: "Actual Novel"), sourcePath: "/tmp/novel.txt", format: .txt)
        _ = try AliasProfileRepository(context: context).upsert(bookID: book.id, profile: .init(aliasTitle: "Quarterly Plan", workbookTitle: "Plan.xlsx", sheetName: "Overview"))
        let item = try XCTUnwrap(LibraryRepository(context: context).fetchItems().first)
        XCTAssertEqual(item.displayTitle, "Quarterly Plan")
        XCTAssertTrue(item.matches("quarterly"))
        XCTAssertTrue(item.matches("actual novel"))
        XCTAssertFalse(item.matches("unrelated"))
    }

    func testRemovingBookCleansAssociatedRecordsButNotSourceFile() throws {
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-library-\(UUID().uuidString).txt")
        try Data("fixture".utf8).write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let book = try BookRepository(context: context).insert(metadata: .init(title: "Book"), sourcePath: sourceURL.path, format: .txt)
        _ = try AliasProfileRepository(context: context).upsert(bookID: book.id, profile: .init(aliasTitle: "Alias", workbookTitle: "Alias.xlsx", sheetName: "Sheet1"))
        _ = try ReadingProgressRepository(context: context).save(locator: .text(chapterID: "main", blockIndex: 1, intraBlockOffset: 0), for: book.id)
        context.insert(OfficeSheetRecord(bookID: book.id)); try context.save()

        try LibraryRepository(context: context).removeBook(id: book.id)

        XCTAssertNil(try BookRepository(context: context).fetch(id: book.id))
        XCTAssertNil(try AliasProfileRepository(context: context).fetch(bookID: book.id))
        XCTAssertNil(try ReadingProgressRepository(context: context).fetch(bookID: book.id))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    }
}
