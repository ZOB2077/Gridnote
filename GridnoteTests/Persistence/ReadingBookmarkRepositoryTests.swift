import SwiftData
import XCTest
@testable import Gridnote

@MainActor
final class ReadingBookmarkRepositoryTests: XCTestCase {
    func testToggleCreatesAndRemovesBookmarkAtExactLocator() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let repository = ReadingBookmarkRepository(context: context)
        let bookID = UUID()
        let locator = ReadingLocator.text(chapterID: "chapter-1", blockIndex: 4, intraBlockOffset: 16)

        XCTAssertTrue(try repository.toggle(bookID: bookID, locator: locator, excerpt: "A saved excerpt"))
        let bookmarks = try repository.bookmarks(for: bookID)
        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.locator, locator)
        XCTAssertEqual(bookmarks.first?.excerpt, "A saved excerpt")

        XCTAssertFalse(try repository.toggle(bookID: bookID, locator: locator, excerpt: "Ignored"))
        XCTAssertTrue(try repository.bookmarks(for: bookID).isEmpty)
    }
}
