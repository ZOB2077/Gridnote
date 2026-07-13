import Foundation
import XCTest
@testable import Gridnote

final class EPUBParserTests: XCTestCase {
    func testParsesMetadataSpineAndNavigation() throws {
        let document = try EPUBParser().parse(data: EPUBFixture.make(), fallbackMetadata: .init(title: "Fallback", sourceFilename: "fixture.epub"), id: UUID())
        XCTAssertEqual(document.metadata.title, "Fixture Book")
        XCTAssertEqual(document.metadata.author, "Gridnote Tests")
        XCTAssertEqual(document.chapters.map(\.id), ["chapter1", "chapter2"])
        XCTAssertEqual(document.toc.map(\.title), ["First", "Second"])
    }

    func testRejectsCorruptedArchive() {
        XCTAssertThrowsError(try EPUBParser().parse(data: Data("not a zip".utf8), fallbackMetadata: .init(title: "Broken", sourceFilename: "broken.epub"), id: UUID()))
    }

    func testRejectsEncryptedEPUB() {
        XCTAssertThrowsError(try EPUBParser().parse(data: EPUBFixture.make(encrypted: true), fallbackMetadata: .init(title: "Encrypted", sourceFilename: "encrypted.epub"), id: UUID()))
    }
}

enum EPUBFixture {
    static func make(encrypted: Bool = false) -> Data {
        var entries: [(String, Data)] = [
            ("mimetype", Data("application/epub+zip".utf8)),
            ("META-INF/container.xml", Data("<?xml version=\"1.0\"?><container><rootfiles><rootfile full-path=\"OEBPS/content.opf\"/></rootfiles></container>".utf8)),
            ("OEBPS/content.opf", Data("<?xml version=\"1.0\"?><package><metadata><dc:title xmlns:dc=\"dc\">Fixture Book</dc:title><dc:creator xmlns:dc=\"dc\">Gridnote Tests</dc:creator></metadata><manifest><item id=\"chapter1\" href=\"chapter1.xhtml\"/><item id=\"chapter2\" href=\"chapter2.xhtml\"/><item id=\"nav\" href=\"nav.xhtml\" properties=\"nav\"/></manifest><spine><itemref idref=\"chapter1\"/><itemref idref=\"chapter2\"/></spine></package>".utf8)),
            ("OEBPS/chapter1.xhtml", Data("<html><head><title>One</title></head><body><h1>Chapter One</h1><p>First paragraph.</p></body></html>".utf8)),
            ("OEBPS/chapter2.xhtml", Data("<html><head><title>Two</title></head><body><h1>Chapter Two</h1><p>Second paragraph.</p></body></html>".utf8)),
            ("OEBPS/nav.xhtml", Data("<html><body><nav><a href=\"chapter1.xhtml\">First</a><a href=\"chapter2.xhtml\">Second</a></nav></body></html>".utf8))
        ]
        if encrypted { entries.append(("META-INF/encryption.xml", Data("<encryption/>".utf8))) }
        return storedZIP(entries)
    }

    static func writeTemporaryFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-\(UUID().uuidString).epub")
        try make().write(to: url)
        return url
    }

    private static func storedZIP(_ entries: [(String, Data)]) -> Data {
        var archive = Data(), central = Data()
        for (name, payload) in entries {
            let nameData = Data(name.utf8), offset = UInt32(archive.count)
            archive.appendLE(UInt32(0x04034b50)); archive.appendLE(UInt16(20)); archive.appendLE(UInt16(0)); archive.appendLE(UInt16(0)); archive.appendLE(UInt16(0)); archive.appendLE(UInt16(0)); archive.appendLE(UInt32(0)); archive.appendLE(UInt32(payload.count)); archive.appendLE(UInt32(payload.count)); archive.appendLE(UInt16(nameData.count)); archive.appendLE(UInt16(0)); archive.append(nameData); archive.append(payload)
            central.appendLE(UInt32(0x02014b50)); central.appendLE(UInt16(20)); central.appendLE(UInt16(20)); central.appendLE(UInt16(0)); central.appendLE(UInt16(0)); central.appendLE(UInt16(0)); central.appendLE(UInt16(0)); central.appendLE(UInt32(0)); central.appendLE(UInt32(payload.count)); central.appendLE(UInt32(payload.count)); central.appendLE(UInt16(nameData.count)); central.appendLE(UInt16(0)); central.appendLE(UInt16(0)); central.appendLE(UInt16(0)); central.appendLE(UInt16(0)); central.appendLE(UInt32(0)); central.appendLE(offset); central.append(nameData)
        }
        let centralOffset = UInt32(archive.count); archive.append(central)
        archive.appendLE(UInt32(0x06054b50)); archive.appendLE(UInt16(0)); archive.appendLE(UInt16(0)); archive.appendLE(UInt16(entries.count)); archive.appendLE(UInt16(entries.count)); archive.appendLE(UInt32(central.count)); archive.appendLE(centralOffset); archive.appendLE(UInt16(0))
        return archive
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var value = value.littleEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }
}
