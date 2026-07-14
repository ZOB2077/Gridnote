import Foundation
import SwiftData

final class AliasProfileRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func upsert(bookID: UUID, profile: AliasProfile) throws -> AliasProfileRecord {
        let existingRecord = try context
            .fetch(FetchDescriptor<AliasProfileRecord>())
            .first { $0.bookID == bookID }
        let record: AliasProfileRecord

        if let existingRecord {
            record = existingRecord
        } else {
            record = AliasProfileRecord(bookID: bookID, profile: profile)
            context.insert(record)
        }
        record.profile = profile
        try context.save()
        return record
    }

    func fetch(bookID: UUID) throws -> AliasProfileRecord? {
        try context.fetch(FetchDescriptor<AliasProfileRecord>()).first { $0.bookID == bookID }
    }
}
