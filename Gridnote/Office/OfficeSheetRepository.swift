import Foundation
import SwiftData

final class OfficeSheetRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) { self.context = context }

    func fetchOrCreate(bookID: UUID?) throws -> OfficeSheetRecord {
        if let record = try context.fetch(FetchDescriptor<OfficeSheetRecord>()).first(where: { $0.bookID == bookID }) {
            return record
        }
        let record = OfficeSheetRecord(bookID: bookID)
        record.gridValuesData = try encoder.encode(OfficeGridSnapshot.defaultOperations)
        context.insert(record)
        try context.save()
        return record
    }

    func snapshot(from record: OfficeSheetRecord) -> OfficeGridSnapshot {
        guard !record.gridValuesData.isEmpty,
              let snapshot = try? decoder.decode(OfficeGridSnapshot.self, from: record.gridValuesData) else {
            return .defaultOperations
        }
        if snapshot.isLegacyOperationsTemplate {
            let upgraded = OfficeGridSnapshot.defaultOperations
            record.gridValuesData = (try? encoder.encode(upgraded)) ?? record.gridValuesData
            try? context.save()
            return upgraded
        }
        return snapshot
    }

    func save(snapshot: OfficeGridSnapshot, selected: OfficeCellCoordinate, sheetName: String, to record: OfficeSheetRecord) throws {
        record.gridValuesData = try encoder.encode(snapshot)
        record.selectedRow = selected.row
        record.selectedColumn = selected.column
        record.activeSheetName = sheetName
        try context.save()
    }
}
