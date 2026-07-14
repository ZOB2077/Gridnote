import Foundation
import SwiftData

final class BookRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func insert(
        metadata: BookMetadata,
        sourcePath: String,
        format: BookFormat
    ) throws -> BookRecord {
        let record = BookRecord(metadata: metadata, sourcePath: sourcePath, format: format)
        context.insert(record)
        try context.save()
        return record
    }

    func fetch(id: UUID) throws -> BookRecord? {
        try context.fetch(FetchDescriptor<BookRecord>()).first { $0.id == id }
    }

    func fetchAll() throws -> [BookRecord] {
        try context.fetch(FetchDescriptor<BookRecord>())
    }

    func fetch(sourcePath: String) throws -> BookRecord? {
        try context.fetch(FetchDescriptor<BookRecord>()).first { $0.sourcePath == sourcePath }
    }

    func fetchLastOpenedOrFirst() throws -> BookRecord? {
        try fetchAll().sorted {
            switch ($0.lastOpenedAt, $1.lastOpenedAt) {
            case let (left?, right?):
                return left > right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return $0.createdAt > $1.createdAt
            }
        }.first
    }

    func delete(_ record: BookRecord) throws {
        context.delete(record)
        try context.save()
    }
}
