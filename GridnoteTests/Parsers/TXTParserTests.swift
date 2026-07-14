import CoreFoundation
import XCTest
@testable import Gridnote

final class TXTParserTests: XCTestCase {
    func testParsesUTF8TextIntoParagraphBlocks() throws {
        let data = Data("第一段\n第二行\n\n第二段".utf8)
        let document = try TXTParser().parse(data: data, metadata: metadata, id: bookID)

        XCTAssertEqual(document.format, .txt)
        XCTAssertEqual(document.chapters.count, 1)
        XCTAssertEqual(document.chapters[0].textBlocks.map(\.text), ["第一段\n第二行", "第二段"])
        XCTAssertEqual(document.toc.first?.chapterID, "txt-main")
    }

    func testParsesUTF16Text() throws {
        let data = try XCTUnwrap("UTF16 第一段\n\n第二段".data(using: .utf16))
        let document = try TXTParser().parse(data: data, metadata: metadata, id: bookID)

        XCTAssertEqual(document.chapters[0].textBlocks.map(\.text), ["UTF16 第一段", "第二段"])
    }

    func testParsesGB18030Text() throws {
        let encoding = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x0632))
        )
        let data = try XCTUnwrap("中文 GB18030\n\n第二段".data(using: encoding))

        let document = try TXTParser().parse(data: data, metadata: metadata, id: bookID)

        XCTAssertEqual(document.chapters[0].textBlocks.map(\.text), ["中文 GB18030", "第二段"])
    }

    func testRecognizesChineseChapterHeadings() throws {
        let data = Data("序章\n故事开端\n\n第一章 初见\n新的旅程\n\n第2章 重逢\n再次相见".utf8)
        let document = try TXTParser().parse(data: data, metadata: metadata, id: bookID)

        XCTAssertEqual(document.chapters.map(\.title), ["序章", "第一章 初见", "第2章 重逢"])
        XCTAssertEqual(document.chapters.map(\.id), ["txt-main", "txt-chapter-2", "txt-chapter-3"])
        XCTAssertEqual(document.toc.map(\.title), document.chapters.map(\.title))
        XCTAssertEqual(document.chapters[1].textBlocks.map(\.text), ["第一章 初见\n新的旅程"])
    }

    func testRecognizesEnglishChapterHeadings() throws {
        let data = Data("Prologue\nOpening scene\n\nChapter 1 The Arrival\nFirst scene\n\nCHAPTER IV\nFourth scene".utf8)
        let document = try TXTParser().parse(data: data, metadata: metadata, id: bookID)

        XCTAssertEqual(document.chapters.map(\.title), ["Prologue", "Chapter 1 The Arrival", "CHAPTER IV"])
    }

    func testCorruptedTextFailsCleanly() {
        let data = Data([0x81, 0x30, 0x81])

        XCTAssertThrowsError(try TXTParser().parse(data: data, metadata: metadata, id: bookID)) { error in
            guard case GridnoteError.parseFailed = error else {
                return XCTFail("Expected parseFailed, got \(error)")
            }
        }
    }

    func testParseCacheLoadsMatchingFingerprintAndVersion() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-cache-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let sourceURL = directoryURL.appendingPathComponent("book.txt")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try Data("cached text".utf8).write(to: sourceURL)

        let cacheStore = TextParseCacheStore(directoryURL: directoryURL.appendingPathComponent("cache"))
        let parser = TXTParser(cacheStore: cacheStore)
        let first = try parser.parse(url: sourceURL, metadata: metadata, id: bookID)
        let second = try parser.parse(url: sourceURL, metadata: metadata, id: bookID)

        XCTAssertEqual(first, second)
    }

    private let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let metadata = BookMetadata(title: "Fixture")
}
