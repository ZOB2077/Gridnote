import Foundation
import SwiftData

enum GridnoteModelContainer {
    static var schema: Schema {
        Schema([
            BookRecord.self,
            AliasProfileRecord.self,
            ReadingProgressRecord.self,
            ReadingBookmarkRecord.self,
            AppSettingsRecord.self,
            OfficeSheetRecord.self,
            WorkspaceSessionRecord.self
        ])
    }

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if let testStorePath = ProcessInfo.processInfo.environment["GRIDNOTE_TEST_STORE_PATH"] {
            configuration = ModelConfiguration(
                schema: schema,
                url: URL(fileURLWithPath: testStorePath)
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
