import SwiftData
import XCTest
@testable import Gridnote

final class PersistenceTests: XCTestCase {
    func testBookAliasAndProgressCanBeCreatedAndQueried() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let bookRepository = BookRepository(context: context)
        let aliasRepository = AliasProfileRepository(context: context)
        let progressRepository = ReadingProgressRepository(context: context)

        let metadata = BookMetadata(
            title: "Test Book",
            author: "Test Author",
            language: "zh-Hans",
            sourceFilename: "test.txt"
        )
        let book = try bookRepository.insert(
            metadata: metadata,
            sourcePath: "/tmp/test.txt",
            format: .txt
        )
        let profile = AliasProfile(
            aliasTitle: "Operations Notes",
            workbookTitle: "Q3 Review.xlsx",
            sheetName: "Overview",
            templateFamily: .projectTracking
        )
        _ = try aliasRepository.upsert(bookID: book.id, profile: profile)
        let locator = ReadingLocator.text(chapterID: "chapter-1", blockIndex: 4, intraBlockOffset: 9)
        _ = try progressRepository.save(locator: locator, for: book.id)

        let fetchedBook = try XCTUnwrap(bookRepository.fetch(id: book.id))
        let fetchedAlias = try XCTUnwrap(aliasRepository.fetch(bookID: book.id))
        let fetchedLocator = try XCTUnwrap(progressRepository.fetchLocator(bookID: book.id))

        XCTAssertEqual(fetchedBook.metadata, metadata)
        XCTAssertEqual(fetchedBook.format, .txt)
        XCTAssertEqual(fetchedAlias.profile, profile)
        XCTAssertEqual(fetchedLocator, locator)
    }
}
