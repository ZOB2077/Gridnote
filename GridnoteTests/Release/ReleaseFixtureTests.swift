import XCTest
@testable import Gridnote

final class ReleaseFixtureTests: XCTestCase {
    func testRequiredFixtureSetIsPresentAndReadable() throws {
        let root = fixtureRoot
        let required = [
            "TXT/utf8-sample.txt", "TXT/utf16-sample.txt", "TXT/gb18030-sample.txt", "TXT/large-20mb.txt",
            "EPUB/basic-with-toc.epub", "EPUB/basic-with-images.epub", "EPUB/corrupted.epub"
        ]
        for path in required {
            XCTAssertTrue(FileManager.default.isReadableFile(atPath: root.appendingPathComponent(path).path), "Missing fixture: \(path)")
        }
    }

    func testReleaseTXTAndEPUBFixturesParse() throws {
        let metadata = BookMetadata(title: "Fixture")
        for name in ["utf8-sample.txt", "utf16-sample.txt", "gb18030-sample.txt"] {
            let document = try TXTParser().parse(data: Data(contentsOf: fixtureRoot.appendingPathComponent("TXT/\(name)")), metadata: metadata, id: UUID())
            XCTAssertFalse(document.chapters.first?.textBlocks.isEmpty ?? true)
        }
        for name in ["basic-with-toc.epub", "basic-with-images.epub"] {
            let document = try EPUBParser().parse(data: Data(contentsOf: fixtureRoot.appendingPathComponent("EPUB/\(name)")), fallbackMetadata: metadata, id: UUID())
            XCTAssertFalse(document.chapters.isEmpty)
            XCTAssertFalse(document.toc.isEmpty)
        }
        XCTAssertThrowsError(try EPUBParser().parse(data: Data(contentsOf: fixtureRoot.appendingPathComponent("EPUB/corrupted.epub")), fallbackMetadata: metadata, id: UUID()))
    }

    func testLargeTXTParserPerformanceSmoke() throws {
        let data = try Data(contentsOf: fixtureRoot.appendingPathComponent("TXT/large-20mb.txt"))
        let start = CFAbsoluteTimeGetCurrent()
        let document = try TXTParser().parse(data: data, metadata: .init(title: "Large Fixture"), id: UUID())
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertFalse(document.chapters.isEmpty)
        XCTAssertLessThan(elapsed, 3.0, "20MB TXT parse exceeded the soft target: \(elapsed)s")
        print("PERF large_txt_parse_seconds=\(String(format: "%.4f", elapsed))")
    }

    private var fixtureRoot: URL {
        Bundle(for: ReleaseFixtureTests.self).resourceURL!.appendingPathComponent("Fixtures")
    }
}
