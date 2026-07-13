import Foundation

final class TextParseCacheStore {
    private struct CacheEnvelope: Codable {
        let parserVersion: Int
        let fingerprint: String
        let document: BookDocument
    }

    private let directoryURL: URL
    private let fileManager: FileManager

    init(
        directoryURL: URL = TextParseCacheStore.defaultDirectoryURL(),
        fileManager: FileManager = .default
    ) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
    }

    func load(fingerprint: String, parserVersion: Int) throws -> BookDocument? {
        let url = cacheFileURL(for: fingerprint)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let envelope = try JSONDecoder().decode(CacheEnvelope.self, from: data)
            guard envelope.fingerprint == fingerprint,
                  envelope.parserVersion == parserVersion else {
                return nil
            }
            return envelope.document
        } catch {
            return nil
        }
    }

    func save(document: BookDocument, fingerprint: String, parserVersion: Int) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let envelope = CacheEnvelope(
            parserVersion: parserVersion,
            fingerprint: fingerprint,
            document: document
        )
        let data = try JSONEncoder().encode(envelope)
        try data.write(to: cacheFileURL(for: fingerprint), options: .atomic)
    }

    func remove(fingerprint: String) throws {
        let url = cacheFileURL(for: fingerprint)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func cacheFileURL(for fingerprint: String) -> URL {
        directoryURL.appendingPathComponent("\(fingerprint).json", isDirectory: false)
    }

    private static func defaultDirectoryURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Gridnote/ParseCache", isDirectory: true)
    }
}
