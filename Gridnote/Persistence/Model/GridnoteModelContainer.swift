import Foundation
import SQLite3
import SwiftData

enum GridnoteModelContainer {
    private static let applicationSupportSubdirectory = "com.gridnote.app"
    private static let storeFilename = "Gridnote.store"

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
        let environment = ProcessInfo.processInfo.environment
        if let testStorePath = environment["GRIDNOTE_TEST_STORE_PATH"] {
            return try make(storeURL: URL(fileURLWithPath: testStorePath))
        }

        if shouldUseInMemoryStore(requested: inMemory, environment: environment) {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        let applicationSupportDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let storeURL = productionStoreURL(applicationSupportDirectory: applicationSupportDirectory)
        try migrateLegacyStoreIfNeeded(
            legacyStoreURL: applicationSupportDirectory.appendingPathComponent("default.store"),
            destinationStoreURL: storeURL
        )
        return try make(storeURL: storeURL)
    }

    static func make(storeURL: URL) throws -> ModelContainer {
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func productionStoreURL(applicationSupportDirectory: URL) -> URL {
        applicationSupportDirectory
            .appendingPathComponent(applicationSupportSubdirectory, isDirectory: true)
            .appendingPathComponent(storeFilename, isDirectory: false)
    }

    static func shouldUseInMemoryStore(
        requested: Bool,
        environment: [String: String]
    ) -> Bool {
        requested || environment["XCTestConfigurationFilePath"] != nil
    }

    static func migrateLegacyStoreIfNeeded(
        legacyStoreURL: URL,
        destinationStoreURL: URL,
        fileManager: FileManager = .default
    ) throws {
        guard !fileManager.fileExists(atPath: destinationStoreURL.path),
              fileManager.fileExists(atPath: legacyStoreURL.path),
              try sqliteStoreContainsGridnoteSchema(at: legacyStoreURL) else {
            return
        }

        try fileManager.createDirectory(
            at: destinationStoreURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let temporaryURL = legacyStoreURL
            .deletingLastPathComponent()
            .appendingPathComponent("Gridnote-migration-\(UUID().uuidString).store")
        defer { try? fileManager.removeItem(at: temporaryURL) }

        try backupSQLiteStore(from: legacyStoreURL, to: temporaryURL)
        try fileManager.moveItem(at: temporaryURL, to: destinationStoreURL)
    }

    private static func sqliteStoreContainsGridnoteSchema(at url: URL) throws -> Bool {
        try withSQLiteDatabase(at: url, flags: SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX) { database in
            try queryReturnsRow(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'ZBOOKRECORD' LIMIT 1",
                database: database,
                storeURL: url
            )
        }
    }

    private static func sqliteDatabasePassesIntegrityCheck(
        _ database: OpaquePointer,
        storeURL: URL
    ) throws -> Bool {
        var statement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(database, "PRAGMA integrity_check", -1, &statement, nil)
        guard prepareResult == SQLITE_OK, let statement else {
            throw sqliteError(database: database, code: prepareResult, storeURL: storeURL)
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW,
              let result = sqlite3_column_text(statement, 0) else {
            return false
        }
        return String(cString: result) == "ok"
    }

    private static func queryReturnsRow(
        _ sql: String,
        database: OpaquePointer,
        storeURL: URL
    ) throws -> Bool {
        var statement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        guard prepareResult == SQLITE_OK, let statement else {
            throw sqliteError(database: database, code: prepareResult, storeURL: storeURL)
        }
        defer { sqlite3_finalize(statement) }

        let stepResult = sqlite3_step(statement)
        switch stepResult {
        case SQLITE_ROW:
            return true
        case SQLITE_DONE:
            return false
        default:
            throw sqliteError(database: database, code: stepResult, storeURL: storeURL)
        }
    }

    private static func backupSQLiteStore(from sourceURL: URL, to destinationURL: URL) throws {
        try withSQLiteDatabase(
            at: sourceURL,
            flags: SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        ) { sourceDatabase in
            try withInMemorySQLiteDatabase { destinationDatabase in
                guard let backup = sqlite3_backup_init(destinationDatabase, "main", sourceDatabase, "main") else {
                    throw sqliteError(
                        database: destinationDatabase,
                        code: sqlite3_errcode(destinationDatabase),
                        storeURL: destinationURL
                    )
                }

                var busyRetries = 0
                var stepResult = SQLITE_OK
                repeat {
                    stepResult = sqlite3_backup_step(backup, 128)
                    if stepResult == SQLITE_BUSY || stepResult == SQLITE_LOCKED {
                        busyRetries += 1
                        guard busyRetries <= 100 else { break }
                        sqlite3_sleep(50)
                    }
                } while stepResult == SQLITE_OK || stepResult == SQLITE_BUSY || stepResult == SQLITE_LOCKED

                let finishResult = sqlite3_backup_finish(backup)
                guard stepResult == SQLITE_DONE, finishResult == SQLITE_OK else {
                    let errorCode = finishResult == SQLITE_OK ? stepResult : finishResult
                    throw sqliteError(
                        database: destinationDatabase,
                        code: errorCode,
                        storeURL: destinationURL
                    )
                }

                guard try queryReturnsRow(
                    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'ZBOOKRECORD' LIMIT 1",
                    database: destinationDatabase,
                    storeURL: destinationURL
                ), try sqliteDatabasePassesIntegrityCheck(
                    destinationDatabase,
                    storeURL: destinationURL
                ) else {
                    throw storageError("The legacy Gridnote store could not be validated after migration.")
                }

                var byteCount: sqlite3_int64 = 0
                guard let bytes = sqlite3_serialize(destinationDatabase, "main", &byteCount, 0),
                      byteCount > 0,
                      byteCount <= 512 * 1_024 * 1_024 else {
                    throw storageError("The migrated Gridnote store has an invalid size.")
                }
                defer { sqlite3_free(bytes) }
                try Data(bytes: bytes, count: Int(byteCount)).write(to: destinationURL, options: .atomic)
            }
        }
    }

    private static func withInMemorySQLiteDatabase<T>(
        operation: (OpaquePointer) throws -> T
    ) throws -> T {
        var database: OpaquePointer?
        let openResult = sqlite3_open(":memory:", &database)
        guard openResult == SQLITE_OK, let database else {
            defer { if let database { sqlite3_close(database) } }
            throw sqliteError(
                database: database,
                code: openResult,
                storeURL: URL(fileURLWithPath: ":memory:")
            )
        }
        defer { sqlite3_close(database) }
        return try operation(database)
    }

    private static func withSQLiteDatabase<T>(
        at url: URL,
        flags: Int32,
        operation: (OpaquePointer) throws -> T
    ) throws -> T {
        var database: OpaquePointer?
        let openResult = sqlite3_open_v2(url.path, &database, flags, nil)
        guard openResult == SQLITE_OK, let database else {
            defer { if let database { sqlite3_close(database) } }
            throw sqliteError(database: database, code: openResult, storeURL: url)
        }
        defer { sqlite3_close(database) }
        sqlite3_busy_timeout(database, 5_000)
        return try operation(database)
    }

    private static func sqliteError(
        database: OpaquePointer?,
        code: Int32,
        storeURL: URL
    ) -> Error {
        let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
        let extendedCode = database.map(sqlite3_extended_errcode) ?? code
        let systemError = database.map(sqlite3_system_errno) ?? 0
        return storageError(
            "SQLite error \(code)/\(extendedCode), errno \(systemError) at \(storeURL.path): \(message)"
        )
    }

    private static func storageError(_ message: String) -> Error {
        NSError(
            domain: "com.gridnote.app.storage",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
