import SwiftData
import XCTest
@testable import Gridnote

final class PersistenceTests: XCTestCase {
    func testLegacyDefaultStoreMigratesIntoApplicationSpecificStore() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-legacy-migration-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let legacyStoreURL = rootURL.appendingPathComponent("default.store", isDirectory: false)
        let destinationStoreURL = rootURL
            .appendingPathComponent("com.gridnote.app", isDirectory: true)
            .appendingPathComponent("Gridnote.store", isDirectory: false)
        var expectedBookID: UUID?

        do {
            let legacyContainer = try GridnoteModelContainer.make(storeURL: legacyStoreURL)
            let repository = BookRepository(context: ModelContext(legacyContainer))
            let book = try repository.insert(
                metadata: BookMetadata(title: "Legacy Book", sourceFilename: "legacy.epub"),
                sourcePath: "/tmp/legacy.epub",
                format: .epub
            )
            expectedBookID = book.id
        }

        try GridnoteModelContainer.migrateLegacyStoreIfNeeded(
            legacyStoreURL: legacyStoreURL,
            destinationStoreURL: destinationStoreURL
        )

        let migratedContainer = try GridnoteModelContainer.make(storeURL: destinationStoreURL)
        let migratedBook = try BookRepository(context: ModelContext(migratedContainer)).fetch(
            id: try XCTUnwrap(expectedBookID)
        )
        XCTAssertEqual(migratedBook?.metadata.title, "Legacy Book")
    }

    func testUnitTestHostUsesInMemoryStoreWithoutAnExplicitFlag() {
        XCTAssertTrue(
            GridnoteModelContainer.shouldUseInMemoryStore(
                requested: false,
                environment: ["XCTestConfigurationFilePath": "/tmp/Gridnote.xctestconfiguration"]
            )
        )
    }

    func testProductionStoreURLIsIsolatedFromTheSharedSwiftDataDefault() {
        let applicationSupportURL = URL(fileURLWithPath: "/tmp/Application Support", isDirectory: true)

        let storeURL = GridnoteModelContainer.productionStoreURL(
            applicationSupportDirectory: applicationSupportURL
        )

        XCTAssertEqual(
            storeURL,
            applicationSupportURL
                .appendingPathComponent("com.gridnote.app", isDirectory: true)
                .appendingPathComponent("Gridnote.store", isDirectory: false)
        )
        XCTAssertNotEqual(storeURL.lastPathComponent, "default.store")
    }

    func testPersistentStoreCreatesItsApplicationSpecificDirectory() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-persistence-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let storeURL = directoryURL.appendingPathComponent("Gridnote.store", isDirectory: false)

        _ = try GridnoteModelContainer.make(storeURL: storeURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.path))
    }

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
