import Foundation
import SwiftData

struct ReadingBookmark: Identifiable, Equatable {
    let id: UUID
    let locator: ReadingLocator
    let excerpt: String
    let createdAt: Date
}

final class ReadingBookmarkRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) { self.context = context }

    func bookmarks(for bookID: UUID) throws -> [ReadingBookmark] {
        try context.fetch(FetchDescriptor<ReadingBookmarkRecord>())
            .filter { $0.bookID == bookID }
            .compactMap { record in
                guard let locator = try? decoder.decode(ReadingLocator.self, from: record.locatorData) else { return nil }
                return ReadingBookmark(id: record.id, locator: locator, excerpt: record.excerpt, createdAt: record.createdAt)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func toggle(bookID: UUID, locator: ReadingLocator, excerpt: String) throws -> Bool {
        let data = try encoder.encode(locator)
        let matches = try context.fetch(FetchDescriptor<ReadingBookmarkRecord>())
            .filter { $0.bookID == bookID && $0.locatorData == data }
        if let existing = matches.first {
            context.delete(existing)
            try context.save()
            return false
        }
        context.insert(ReadingBookmarkRecord(bookID: bookID, locatorData: data, excerpt: excerpt))
        try context.save()
        return true
    }

    func delete(id: UUID) throws {
        guard let record = try context.fetch(FetchDescriptor<ReadingBookmarkRecord>()).first(where: { $0.id == id }) else { return }
        context.delete(record)
        try context.save()
    }
}
