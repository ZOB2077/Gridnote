import Foundation
import SwiftData

@Model
final class ReadingProgressRecord {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var locatorData: Data?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        bookID: UUID,
        locatorData: Data? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.bookID = bookID
        self.locatorData = locatorData
        self.updatedAt = updatedAt
    }
}
