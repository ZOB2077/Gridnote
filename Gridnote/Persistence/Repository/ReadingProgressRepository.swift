import Foundation
import SwiftData

enum ReadingProgressSyncSource: String {
    case office
    case floatingReader
}

enum ReadingProgressSync {
    static let bookIDKey = "bookID"

    static func post(bookID: UUID, source: ReadingProgressSyncSource) {
        NotificationCenter.default.post(
            name: .gridnoteReadingProgressDidChange,
            object: source.rawValue,
            userInfo: [bookIDKey: bookID]
        )
    }
}

extension Notification.Name {
    static let gridnoteReadingProgressDidChange = Notification.Name("GridnoteReadingProgressDidChange")
}

final class ReadingProgressRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func save(locator: ReadingLocator, for bookID: UUID, at date: Date = .now) throws -> ReadingProgressRecord {
        let existingRecord = try context
            .fetch(FetchDescriptor<ReadingProgressRecord>())
            .first { $0.bookID == bookID }
        let record: ReadingProgressRecord

        if let existingRecord {
            record = existingRecord
        } else {
            record = ReadingProgressRecord(bookID: bookID)
            context.insert(record)
        }
        record.locatorData = try encoder.encode(locator)
        record.updatedAt = date
        try context.save()
        return record
    }

    func fetch(bookID: UUID) throws -> ReadingProgressRecord? {
        try context.fetch(FetchDescriptor<ReadingProgressRecord>()).first { $0.bookID == bookID }
    }

    func fetchLocator(bookID: UUID) throws -> ReadingLocator? {
        guard let data = try fetch(bookID: bookID)?.locatorData else { return nil }
        return try decoder.decode(ReadingLocator.self, from: data)
    }
}
