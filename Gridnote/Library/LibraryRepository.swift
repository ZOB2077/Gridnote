import Foundation
import SwiftData

struct LibraryItem: Identifiable, Equatable {
    let id: UUID
    let displayTitle: String
    let actualTitle: String
    let author: String?
    let format: BookFormat
    let sourcePath: String
    let sourceStatus: SourceStatus
    let lastOpenedAt: Date?

    func matches(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty || displayTitle.localizedCaseInsensitiveContains(normalized) || actualTitle.localizedCaseInsensitiveContains(normalized)
    }
}

final class LibraryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItems() throws -> [LibraryItem] {
        let books = try context.fetch(FetchDescriptor<BookRecord>())
        let aliases = try context.fetch(FetchDescriptor<AliasProfileRecord>())
        let aliasesByBook = Dictionary(uniqueKeysWithValues: aliases.map { ($0.bookID, $0.aliasTitle) })
        return books.map { book in
            LibraryItem(
                id: book.id,
                displayTitle: aliasesByBook[book.id].flatMap { $0.isEmpty ? nil : $0 } ?? book.detectedTitle,
                actualTitle: book.detectedTitle,
                author: book.detectedAuthor,
                format: book.format,
                sourcePath: book.sourcePath,
                sourceStatus: book.sourceStatus,
                lastOpenedAt: book.lastOpenedAt
            )
        }.sorted {
            if $0.lastOpenedAt != $1.lastOpenedAt { return ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
            return $0.displayTitle.localizedStandardCompare($1.displayTitle) == .orderedAscending
        }
    }

    func removeBook(id: UUID) throws {
        if let book = try context.fetch(FetchDescriptor<BookRecord>()).first(where: { $0.id == id }) { context.delete(book) }
        for alias in try context.fetch(FetchDescriptor<AliasProfileRecord>()).filter({ $0.bookID == id }) { context.delete(alias) }
        for progress in try context.fetch(FetchDescriptor<ReadingProgressRecord>()).filter({ $0.bookID == id }) { context.delete(progress) }
        for bookmark in try context.fetch(FetchDescriptor<ReadingBookmarkRecord>()).filter({ $0.bookID == id }) { context.delete(bookmark) }
        for sheet in try context.fetch(FetchDescriptor<OfficeSheetRecord>()).filter({ $0.bookID == id }) { context.delete(sheet) }
        try context.save()
    }
}
