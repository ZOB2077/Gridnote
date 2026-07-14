import CryptoKit
import Foundation

final class EPUBParser: BookDocumentParser {
    static let parserVersion = 1
    private let cacheStore: TextParseCacheStore?

    init(cacheStore: TextParseCacheStore? = nil) {
        self.cacheStore = cacheStore
    }

    func parse(url: URL, metadata: BookMetadata, id: UUID) throws -> BookDocument {
        let data = try Data(contentsOf: url)
        let fingerprint = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        if let cached = try cacheStore?.load(fingerprint: fingerprint, parserVersion: Self.parserVersion) {
            return cached
        }
        let document = try parse(data: data, fallbackMetadata: metadata, id: id)
        try cacheStore?.save(document: document, fingerprint: fingerprint, parserVersion: Self.parserVersion)
        return document
    }

    func parse(data: Data, fallbackMetadata: BookMetadata, id: UUID) throws -> BookDocument {
        let archive = try EPUBArchive(data: data)
        if archive.contains("META-INF/encryption.xml") {
            throw GridnoteError.parseFailed("Encrypted or DRM-protected EPUB is not supported")
        }
        let container = try XMLTree(data: archive.data(at: "META-INF/container.xml"))
        guard let packagePath = container.firstAttribute("full-path", on: "rootfile") else {
            throw GridnoteError.parseFailed("EPUB package path is missing")
        }
        let package = try XMLTree(data: archive.data(at: packagePath))
        let base = (packagePath as NSString).deletingLastPathComponent
        let title = package.firstText("title") ?? fallbackMetadata.title
        let author = package.firstText("creator") ?? fallbackMetadata.author
        let language = package.firstText("language") ?? fallbackMetadata.language
        let metadata = BookMetadata(title: title, author: author, language: language, sourceFilename: fallbackMetadata.sourceFilename)

        let manifest = package.elements(named: "item").reduce(into: [String: XMLTree.Element]()) { result, item in
            if let key = item.attributes["id"] { result[key] = item }
        }
        let spineIDs = package.elements(named: "itemref").compactMap { $0.attributes["idref"] }
        var chapters: [BookChapter] = []
        for spineID in spineIDs {
            guard let item = manifest[spineID], let href = item.attributes["href"] else { continue }
            let path = Self.resolve(href, relativeTo: base)
            let content = try XMLTree(data: archive.data(at: path))
            let paragraphs = content.readingParagraphs()
            guard !paragraphs.isEmpty else { continue }
            let chapterTitle = content.firstText("title") ?? content.firstText("h1") ?? title
            chapters.append(BookChapter(
                id: spineID,
                title: chapterTitle,
                textBlocks: paragraphs.enumerated().map { TextBlock(id: "\(spineID)-block-\($0.offset + 1)", text: $0.element) }
            ))
        }
        guard !chapters.isEmpty else { throw GridnoteError.parseFailed("EPUB contains no readable chapters") }

        var toc: [TOCEntry] = []
        if let nav = manifest.values.first(where: { $0.attributes["properties"]?.split(separator: " ").contains("nav") == true }),
           let href = nav.attributes["href"] {
            let navTree = try XMLTree(data: archive.data(at: Self.resolve(href, relativeTo: base)))
            toc = navTree.links().compactMap { link in
                let target = link.href.split(separator: "#").first.map(String.init) ?? link.href
                let resolved = Self.resolve(target, relativeTo: base)
                guard let chapter = chapters.first(where: { manifest[$0.id].flatMap { $0.attributes["href"] }.map { Self.resolve($0, relativeTo: base) } == resolved }) else { return nil }
                return TOCEntry(title: link.title, chapterID: chapter.id, depth: 0)
            }
        }
        if toc.isEmpty {
            toc = chapters.map { TOCEntry(title: $0.title, chapterID: $0.id, depth: 0) }
        }
        return BookDocument(id: id, format: .epub, metadata: metadata, chapters: chapters, toc: toc)
    }

    private static func resolve(_ path: String, relativeTo base: String) -> String {
        let decoded = path.removingPercentEncoding ?? path
        return ((base as NSString).appendingPathComponent(decoded) as NSString).standardizingPath
    }
}

private final class XMLTree: NSObject, XMLParserDelegate {
    struct Element {
        let name: String
        let attributes: [String: String]
        var text: String
    }

    private(set) var parsedElements: [Element] = []
    private var stack: [Int] = []

    init(data: Data) throws {
        super.init()
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { throw GridnoteError.parseFailed("Malformed EPUB XML") }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        parsedElements.append(Element(name: Self.localName(elementName), attributes: attributeDict, text: ""))
        stack.append(parsedElements.count - 1)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        for index in stack { parsedElements[index].text += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        _ = stack.popLast()
    }

    func elements(named name: String) -> [Element] { parsedElements.filter { $0.name == name } }
    func firstText(_ name: String) -> String? { elements(named: name).compactMap { Self.cleaned($0.text) }.first }
    func firstAttribute(_ attribute: String, on name: String) -> String? { elements(named: name).first?.attributes[attribute] }
    func readingParagraphs() -> [String] {
        let preferred = parsedElements.filter { ["p", "h1", "h2", "h3", "li", "blockquote"].contains($0.name) }.compactMap { Self.cleaned($0.text) }
        return preferred.isEmpty ? parsedElements.filter { $0.name == "body" }.compactMap { Self.cleaned($0.text) } : preferred
    }
    func links() -> [(title: String, href: String)] {
        elements(named: "a").compactMap { element in
            guard let title = Self.cleaned(element.text), let href = element.attributes["href"] else { return nil }
            return (title, href)
        }
    }

    private static func localName(_ name: String) -> String { name.split(separator: ":").last.map(String.init) ?? name }
    private static func cleaned(_ value: String) -> String? {
        let text = value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return text.isEmpty ? nil : text
    }
}
