import CoreFoundation
import CryptoKit
import Foundation

final class TXTParser: BookDocumentParser {
    static let parserVersion = 2

    private let cacheStore: TextParseCacheStore?

    init(cacheStore: TextParseCacheStore? = nil) {
        self.cacheStore = cacheStore
    }

    func parse(url: URL, metadata: BookMetadata, id: UUID) throws -> BookDocument {
        let data = try Data(contentsOf: url)
        let fingerprint = Self.fingerprint(for: data)

        if let cached = try cacheStore?.load(fingerprint: fingerprint, parserVersion: Self.parserVersion) {
            return cached
        }

        let document = try parse(data: data, metadata: metadata, id: id)
        try cacheStore?.save(document: document, fingerprint: fingerprint, parserVersion: Self.parserVersion)
        return document
    }

    func parse(data: Data, metadata: BookMetadata, id: UUID) throws -> BookDocument {
        guard !data.isEmpty else {
            throw GridnoteError.parseFailed("TXT file is empty")
        }

        let text = try Self.decode(data: data)
        let normalized = Self.normalizeLineEndings(text)
        let chapters = Self.chapters(from: normalized, fallbackTitle: metadata.title)

        guard !chapters.isEmpty else {
            throw GridnoteError.parseFailed("TXT file does not contain readable text")
        }

        return BookDocument(
            id: id,
            format: .txt,
            metadata: metadata,
            chapters: chapters,
            toc: chapters.map { TOCEntry(title: $0.title, chapterID: $0.id, depth: 0) }
        )
    }

    static func decode(data: Data) throws -> String {
        let encodings = preferredEncodings(for: data)

        for encoding in encodings {
            if let decoded = String(data: data, encoding: encoding),
               isPlausibleText(decoded) {
                let cleaned = decoded.trimmingCharacters(in: CharacterSet(charactersIn: "\u{feff}"))
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }

        throw GridnoteError.parseFailed("Unsupported TXT encoding")
    }

    private static func preferredEncodings(for data: Data) -> [String.Encoding] {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            return [.utf8]
        }
        if data.starts(with: [0xFF, 0xFE]) {
            return [.utf16LittleEndian, .utf16]
        }
        if data.starts(with: [0xFE, 0xFF]) {
            return [.utf16BigEndian, .utf16]
        }
        return [.utf8, gb18030Encoding]
    }

    private static func isPlausibleText(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar == "\u{fffd}" {
                return false
            }
            if scalar.value < 0x20,
               scalar != "\n",
               scalar != "\r",
               scalar != "\t" {
                return false
            }
        }
        return true
    }

    static func normalizeLineEndings(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    static func paragraphs(from text: String) -> [String] {
        paragraphs(from: text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
    }

    private static func chapters(from text: String, fallbackTitle: String) -> [BookChapter] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var result: [BookChapter] = []
        var title = fallbackTitle
        var chapterLines: [String] = []

        func flushChapter() {
            let blocks = paragraphs(from: chapterLines)
            guard !blocks.isEmpty else { return }
            let chapterIndex = result.count + 1
            let id = chapterIndex == 1 ? "txt-main" : "txt-chapter-\(chapterIndex)"
            result.append(BookChapter(
                id: id,
                title: title,
                textBlocks: blocks.enumerated().map { index, paragraph in
                    TextBlock(id: "\(id)-block-\(index + 1)", text: paragraph)
                }
            ))
            chapterLines.removeAll(keepingCapacity: true)
        }

        for rawLine in lines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if let heading = chapterHeading(from: trimmed) {
                flushChapter()
                title = heading
                // Retain the heading in the reading flow so jumps have clear context.
                chapterLines.append(heading)
            } else {
                chapterLines.append(trimmed)
            }
        }
        flushChapter()
        return result
    }

    private static func paragraphs(from lines: [String]) -> [String] {
        var paragraphs: [String] = []
        var currentLines: [String] = []
        var currentCharacterCount = 0
        let preferredBlockSize = 4_096

        func flush() {
            guard !currentLines.isEmpty else { return }
            paragraphs.append(currentLines.joined(separator: "\n"))
            currentLines.removeAll(keepingCapacity: true)
            currentCharacterCount = 0
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                flush()
            } else {
                currentLines.append(trimmed)
                currentCharacterCount += trimmed.count + 1
                if currentCharacterCount >= preferredBlockSize {
                    flush()
                }
            }
        }

        flush()
        return paragraphs
    }

    private static func chapterHeading(from line: String) -> String? {
        guard !line.isEmpty, line.count <= 80 else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        return chineseChapterExpression.firstMatch(in: line, range: range) != nil
            || englishChapterExpression.firstMatch(in: line, range: range) != nil
            ? line
            : nil
    }

    private static let chineseChapterExpression = try! NSRegularExpression(
        pattern: "^(?:第\\s*[0-9０-９一二三四五六七八九十百千万零〇两]+\\s*[章节卷回篇].{0,48}|(?:序章|楔子|前言|后记|尾声|番外).{0,48})$"
    )

    private static let englishChapterExpression = try! NSRegularExpression(
        pattern: "^(?i:(?:chapter\\s+(?:[0-9]+|[ivxlcdm]+).{0,48}|prologue|epilogue))$"
    )

    static func fingerprint(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static let gb18030Encoding = String.Encoding(
        rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x0632))
    )
}
