import Foundation
import SwiftData

@Model
final class ReadingBookmarkRecord {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var locatorData: Data
    var excerpt: String
    var createdAt: Date

    init(id: UUID = UUID(), bookID: UUID, locatorData: Data, excerpt: String, createdAt: Date = .now) {
        self.id = id
        self.bookID = bookID
        self.locatorData = locatorData
        self.excerpt = excerpt
        self.createdAt = createdAt
    }
}
