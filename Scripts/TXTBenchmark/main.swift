import Foundation

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: txt-benchmark <fixture-path>")
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try Data(contentsOf: url)
let start = CFAbsoluteTimeGetCurrent()
let document = try TXTParser().parse(data: data, metadata: .init(title: "Benchmark"), id: UUID())
let elapsed = CFAbsoluteTimeGetCurrent() - start
print("large_txt_bytes=\(data.count)")
print("large_txt_blocks=\(document.chapters.first?.textBlocks.count ?? 0)")
print("large_txt_parse_seconds=\(String(format: "%.4f", elapsed))")

let cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-benchmark-cache-\(UUID().uuidString)")
defer { try? FileManager.default.removeItem(at: cacheDirectory) }
let cache = TextParseCacheStore(directoryURL: cacheDirectory)
let cachedParser = TXTParser(cacheStore: cache)
_ = try cachedParser.parse(url: url, metadata: .init(title: "Benchmark"), id: UUID())
let reopenStart = CFAbsoluteTimeGetCurrent()
_ = try cachedParser.parse(url: url, metadata: .init(title: "Benchmark"), id: UUID())
let reopenElapsed = CFAbsoluteTimeGetCurrent() - reopenStart
print("cached_reopen_seconds=\(String(format: "%.4f", reopenElapsed))")
