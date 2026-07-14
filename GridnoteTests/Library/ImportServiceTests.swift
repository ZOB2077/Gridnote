import SwiftData
import XCTest
@testable import Gridnote

final class ImportServiceTests: XCTestCase {
    func testSupportedFileIsRecordedWithBookmarkAndFormat() throws {
        let sourceURL = try makeTemporaryFile(extension: "txt")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let bookmarkStore = TestBookmarkStore()
        let service = ImportService(context: context, bookmarkStore: bookmarkStore)

        let record = try service.importFile(from: sourceURL)

        XCTAssertEqual(record.format, .txt)
        XCTAssertEqual(record.sourceStatus, .available)
        XCTAssertEqual(record.sourcePath, sourceURL.path)
        XCTAssertNotNil(record.sourceBookmarkData)
        XCTAssertEqual(try BookRepository(context: context).fetchAll().count, 1)
    }

    func testPDFIsRejectedWithoutCreatingRecord() throws {
        let sourceURL = try makeTemporaryFile(extension: "pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let service = ImportService(context: context, bookmarkStore: TestBookmarkStore())

        XCTAssertThrowsError(try service.importFile(from: sourceURL))
        XCTAssertEqual(try BookRepository(context: context).fetchAll().count, 0)
    }

    func testBookmarkFailureDoesNotCreateRecord() throws {
        let sourceURL = try makeTemporaryFile(extension: "txt")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let bookmarkStore = TestBookmarkStore()
        bookmarkStore.failOnCreate = true
        let service = ImportService(context: context, bookmarkStore: bookmarkStore)

        XCTAssertThrowsError(try service.importFile(from: sourceURL))
        XCTAssertEqual(try BookRepository(context: context).fetchAll().count, 0)
    }

    func testMissingSourceCanBeRelinked() throws {
        let originalURL = try makeTemporaryFile(extension: "epub")
        let replacementURL = try makeTemporaryFile(extension: "epub")
        defer {
            try? FileManager.default.removeItem(at: originalURL)
            try? FileManager.default.removeItem(at: replacementURL)
        }

        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let bookmarkStore = TestBookmarkStore()
        let service = ImportService(context: context, bookmarkStore: bookmarkStore)
        let record = try service.importFile(from: originalURL)

        try FileManager.default.removeItem(at: originalURL)
        XCTAssertEqual(try service.refreshSourceStatus(for: record), .missing)

        let relinked = try service.relink(record: record, to: replacementURL)
        XCTAssertEqual(relinked.sourceStatus, .available)
        XCTAssertEqual(relinked.sourcePath, replacementURL.path)
    }

    private func makeTemporaryFile(extension fileExtension: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-\(UUID().uuidString)")
            .appendingPathExtension(fileExtension)
        try Data("fixture".utf8).write(to: url)
        return url
    }
}

private final class TestBookmarkStore: BookmarkStore {
    var failOnCreate = false
    private var urls: [Data: URL] = [:]

    func makeBookmark(for url: URL) throws -> Data {
        if failOnCreate { throw GridnoteError.bookmarkCreationFailed }
        let data = Data(url.path.utf8)
        urls[data] = url
        return data
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        guard let url = urls[data] else { throw GridnoteError.sourceUnavailable("bookmark") }
        return url
    }
}
