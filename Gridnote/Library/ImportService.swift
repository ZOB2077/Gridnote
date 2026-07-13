import Foundation
import SwiftData
import UniformTypeIdentifiers

final class ImportService {
    static let supportedContentTypes: [UTType] = [
        .plainText,
        UTType(filenameExtension: "epub") ?? .data
    ]

    private let context: ModelContext
    private let bookmarkStore: BookmarkStore
    private let fileManager: FileManager

    init(
        context: ModelContext,
        bookmarkStore: BookmarkStore = SecurityScopedBookmarkStore(),
        fileManager: FileManager = .default
    ) {
        self.context = context
        self.bookmarkStore = bookmarkStore
        self.fileManager = fileManager
    }

    static func detectFormat(for url: URL) throws -> BookFormat {
        switch url.pathExtension.lowercased() {
        case BookFormat.txt.rawValue:
            return .txt
        case BookFormat.epub.rawValue:
            return .epub
        default:
            throw GridnoteError.unsupportedFormat(url.pathExtension)
        }
    }

    @discardableResult
    func importFile(from url: URL) throws -> BookRecord {
        let format = try Self.detectFormat(for: url)
        try validateReadableSource(url)
        let bookmarkData = try bookmarkStore.makeBookmark(for: url)

        let metadata = BookMetadata(
            title: url.deletingPathExtension().lastPathComponent,
            sourceFilename: url.lastPathComponent
        )
        let record = BookRecord(
            metadata: metadata,
            sourcePath: url.path,
            format: format
        )
        record.sourceBookmarkData = bookmarkData
        record.sourceStatus = .available
        context.insert(record)
        try context.save()
        return record
    }

    @discardableResult
    func refreshSourceStatus(for record: BookRecord) throws -> SourceStatus {
        guard let bookmarkData = record.sourceBookmarkData else {
            record.sourceStatus = .missing
            try context.save()
            return .missing
        }

        do {
            let resolvedURL = try bookmarkStore.resolveBookmark(bookmarkData)
            record.sourceStatus = fileManager.isReadableFile(atPath: resolvedURL.path) ? .available : .missing
        } catch {
            record.sourceStatus = .accessDenied
        }
        try context.save()
        return record.sourceStatus
    }

    @discardableResult
    func relink(record: BookRecord, to url: URL) throws -> BookRecord {
        let format = try Self.detectFormat(for: url)
        try validateReadableSource(url)
        let bookmarkData = try bookmarkStore.makeBookmark(for: url)

        record.sourcePath = url.path
        record.sourceFilename = url.lastPathComponent
        record.sourceBookmarkData = bookmarkData
        record.format = format
        record.sourceStatus = .available
        try context.save()
        return record
    }

    private func validateReadableSource(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path), fileManager.isReadableFile(atPath: url.path) else {
            throw GridnoteError.sourceUnavailable(url.path)
        }
    }
}
