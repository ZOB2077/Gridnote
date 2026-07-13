import Foundation
import SwiftData

final class AppSettingsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchOrCreate() throws -> AppSettingsRecord {
        if let existing = try context.fetch(FetchDescriptor<AppSettingsRecord>()).first {
            return existing
        }

        let record = AppSettingsRecord()
        context.insert(record)
        try context.save()
        return record
    }

    func updateStandardReaderFontSize(_ fontSize: Double) throws {
        let record = try fetchOrCreate()
        record.standardReaderFontSize = fontSize
        try context.save()
    }

    func updateResignToOfficeOnDeactivate(_ enabled: Bool) throws {
        let record = try fetchOrCreate()
        record.resignToOfficeOnDeactivate = enabled
        try context.save()
    }

    func updateReader(fontSize: Double, lineHeight: Double, theme: String) throws {
        let record = try fetchOrCreate()
        record.standardReaderFontSize = fontSize
        record.standardReaderLineHeight = lineHeight
        record.readerThemeRawValue = theme
        try context.save()
    }
}
