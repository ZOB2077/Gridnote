import Foundation
import SwiftData
import SwiftUI

enum StealthAppearance: String, CaseIterable, Identifiable {
    case activity
    case report
    case console

    var id: String { rawValue }

    var title: String {
        switch self {
        case .activity: String(localized: "Activity")
        case .report: String(localized: "Weekly Report")
        case .console: String(localized: "Console")
        }
    }
}

enum FloatingReaderDensity: String, CaseIterable, Hashable, Identifiable {
    case spacious
    case balanced
    case compact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spacious: String(localized: "Spacious")
        case .balanced: String(localized: "Balanced")
        case .compact: String(localized: "Compact")
        }
    }

    var fontSize: Double {
        switch self {
        case .spacious: 17
        case .balanced: 14
        case .compact: 12
        }
    }

    var lineSpacing: Double {
        switch self {
        case .spacious: 8
        case .balanced: 4
        case .compact: 1
        }
    }
}

enum FloatingReaderPageDirection: Equatable {
    case forward
    case backward
}

struct FloatingReaderChapter: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let offset: Int
}

@MainActor
final class StealthReaderViewModel: ObservableObject {
    enum State: Equatable {
        case empty
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var state: State = .empty
    @Published private(set) var pageText = String(localized: "Select a record to inspect its notes.")
    @Published private(set) var progressText = ""
    @Published private(set) var progressFraction = 0.0
    @Published private(set) var bookmarks: [ReadingBookmark] = []
    @Published private(set) var chapters: [FloatingReaderChapter] = []
    @Published private(set) var isCurrentLocationBookmarked = false
    @Published private(set) var searchResultText = ""
    @Published private(set) var pageRevision = 0
    @Published private(set) var pageDirection: FloatingReaderPageDirection = .forward
    @Published var charactersPerPage: Int {
        didSet {
            defaults.set(charactersPerPage, forKey: Keys.charactersPerPage)
            refreshPage()
        }
    }
    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }
    @Published var lineSpacing: Double {
        didSet { defaults.set(lineSpacing, forKey: Keys.lineSpacing) }
    }
    @Published var backgroundOpacity: Double {
        didSet { defaults.set(backgroundOpacity, forKey: Keys.backgroundOpacity) }
    }
    @Published var textColor: Color {
        didSet {
            guard !isReloadingPresentation else { return }
            ReaderPresentationSettings.save(color: textColor, opacity: textOpacity, to: presentationDefaults)
        }
    }
    @Published var textOpacity: Double {
        didSet {
            guard !isReloadingPresentation else { return }
            ReaderPresentationSettings.save(color: textColor, opacity: textOpacity, to: presentationDefaults)
        }
    }
    @Published var appearance: StealthAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    @Published private(set) var density: FloatingReaderDensity

    private struct LoadRequest: Sendable {
        let id: UUID
        let sourcePath: String
        let format: BookFormat
        let metadata: BookMetadata
        let locator: ReadingLocator?
    }

    private struct PreparedDocument: Sendable {
        let text: String
        let spans: [BlockSpan]
        let chapters: [FloatingReaderChapter]
    }

    private struct BlockSpan: Sendable {
        let chapterID: String
        let blockIndex: Int
        let format: BookFormat
        let range: Range<Int>
    }

    private enum Keys {
        static let charactersPerPage = "stealthReader.charactersPerPage"
        static let fontSize = "stealthReader.fontSize"
        static let lineSpacing = "stealthReader.lineSpacing"
        static let backgroundOpacity = "stealthReader.backgroundOpacity"
        static let appearance = "stealthReader.appearance"
        static let density = "stealthReader.density"
    }

    private let context: ModelContext
    private let defaults: UserDefaults
    private let presentationDefaults: UserDefaults
    private var fullText: NSString = ""
    private var spans: [BlockSpan] = []
    private var offset = 0
    private var bookID: UUID?
    private var isReloadingPresentation = false

    init(
        context: ModelContext,
        defaults: UserDefaults = .standard,
        presentationDefaults: UserDefaults? = nil
    ) {
        self.context = context
        self.defaults = defaults
        self.presentationDefaults = presentationDefaults ?? defaults
        charactersPerPage = min(max(defaults.object(forKey: Keys.charactersPerPage) as? Int ?? 360, 80), 1600)
        fontSize = min(max(defaults.object(forKey: Keys.fontSize) as? Double ?? 14, 10), 28)
        lineSpacing = min(max(defaults.object(forKey: Keys.lineSpacing) as? Double ?? 4, 0), 12)
        backgroundOpacity = min(max(defaults.object(forKey: Keys.backgroundOpacity) as? Double ?? 0.94, 0), 1)
        textColor = ReaderPresentationSettings.textColor(in: self.presentationDefaults)
        textOpacity = ReaderPresentationSettings.textOpacity(in: self.presentationDefaults)
        appearance = StealthAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .activity
        density = FloatingReaderDensity(rawValue: defaults.string(forKey: Keys.density) ?? "") ?? .balanced
    }

    var canGoPrevious: Bool { offset > 0 }
    var canGoNext: Bool { offset + charactersPerPage < fullText.length }

    func reloadPresentationSettings() {
        isReloadingPresentation = true
        defer { isReloadingPresentation = false }
        textColor = ReaderPresentationSettings.textColor(in: presentationDefaults)
        textOpacity = ReaderPresentationSettings.textOpacity(in: presentationDefaults)
    }

    func load(bookID requestedBookID: UUID?) async {
        state = .loading
        chapters = []
        pageText = String(localized: "Refreshing workspace details...")
        progressText = String(localized: "Preparing")
        progressFraction = 0

        do {
            let repository = BookRepository(context: context)
            let record = try requestedBookID.flatMap { try repository.fetch(id: $0) }
                ?? repository.fetchLastOpenedOrFirst()
            guard let record else {
                state = .empty
                chapters = []
                pageText = String(localized: "Select a record to inspect its notes.")
                progressText = String(localized: "No selection")
                return
            }
            let request = LoadRequest(
                id: record.id,
                sourcePath: record.sourcePath,
                format: record.format,
                metadata: record.metadata,
                locator: try ReadingProgressRepository(context: context).fetchLocator(bookID: record.id)
            )

            let prepared = try await Task.detached(priority: .userInitiated) {
                try Task.checkCancellation()
                let sourceURL = URL(fileURLWithPath: request.sourcePath)
                let cache = TextParseCacheStore()
                let document: BookDocument = switch request.format {
                case .txt:
                    try TXTParser(cacheStore: cache).parse(url: sourceURL, metadata: request.metadata, id: request.id)
                case .epub:
                    try EPUBParser(cacheStore: cache).parse(url: sourceURL, metadata: request.metadata, id: request.id)
                }
                try Task.checkCancellation()
                return Self.prepare(document: document, format: request.format)
            }.value

            try Task.checkCancellation()
            fullText = prepared.text as NSString
            spans = prepared.spans
            chapters = prepared.chapters
            offset = 0
            bookID = request.id
            restore(request.locator)
            state = .ready
            refreshPage()
            reloadBookmarks()
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
            chapters = []
            pageText = String(localized: "Workspace data could not be refreshed.") + "\n\n\(error.localizedDescription)"
            progressText = String(localized: "Unavailable")
            progressFraction = 0
        }
    }

    func next() {
        guard canGoNext else { return }
        offset = min(offset + charactersPerPage, max(fullText.length - 1, 0))
        refreshPage(animated: true, direction: .forward)
        saveProgress()
    }

    func previous() {
        guard canGoPrevious else { return }
        offset = max(offset - charactersPerPage, 0)
        refreshPage(animated: true, direction: .backward)
        saveProgress()
    }

    func seek(to fraction: Double) {
        guard fullText.length > 0 else { return }
        let rawOffset = Int(Double(max(fullText.length - 1, 0)) * min(max(fraction, 0), 1))
        let direction: FloatingReaderPageDirection = rawOffset >= offset ? .forward : .backward
        offset = rawOffset - rawOffset % charactersPerPage
        refreshPage(animated: true, direction: direction)
        saveProgress()
    }

    /// Keeps each page inside the current floating panel instead of relying on vertical scrolling.
    func fitPage(to size: CGSize, maximumLines: Int? = nil) {
        let usableWidth = max(size.width - 32, 120)
        let usableHeight = max(size.height - (maximumLines == nil ? 26 : 8), 16)
        let estimatedCharacterWidth = max(fontSize * 0.68, 7)
        let estimatedLineHeight = max(fontSize + lineSpacing + 7, 16)
        let charactersPerLine = max(8, Int(usableWidth / estimatedCharacterWidth))
        let fittedLines = max(1, Int(usableHeight / estimatedLineHeight))
        let visibleLines = maximumLines.map { min(fittedLines, max($0, 1)) } ?? max(3, fittedLines)
        let minimumCapacity = maximumLines == nil ? 80 : 8
        let fittedCapacity = min(max(charactersPerLine * visibleLines, minimumCapacity), 1600)

        guard fittedCapacity != charactersPerPage else { return }
        charactersPerPage = fittedCapacity
    }

    func goToStart() {
        offset = 0
        refreshPage(animated: true, direction: .backward)
        saveProgress()
    }

    func jump(to chapter: FloatingReaderChapter) {
        guard fullText.length > 0 else { return }
        let direction: FloatingReaderPageDirection = chapter.offset >= offset ? .forward : .backward
        offset = min(max(chapter.offset, 0), fullText.length - 1)
        refreshPage(animated: true, direction: direction)
        saveProgress()
    }

    func toggleBookmark() {
        guard let bookID, let locator = currentLocator else { return }
        let excerpt = pageText.replacingOccurrences(of: "\n", with: " ").prefix(72).description
        _ = try? ReadingBookmarkRepository(context: context).toggle(bookID: bookID, locator: locator, excerpt: excerpt)
        reloadBookmarks()
    }

    func jump(to bookmark: ReadingBookmark) {
        let originalOffset = offset
        restore(bookmark.locator)
        refreshPage(animated: true, direction: offset >= originalOffset ? .forward : .backward)
        saveProgress()
    }

    func deleteBookmark(_ bookmark: ReadingBookmark) {
        try? ReadingBookmarkRepository(context: context).delete(id: bookmark.id)
        reloadBookmarks()
    }

    func search(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, fullText.length > 0 else {
            searchResultText = ""
            return
        }
        let searchRange = NSRange(location: min(offset + 1, fullText.length), length: max(0, fullText.length - min(offset + 1, fullText.length)))
        let firstPass = fullText.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange)
        let found = firstPass.location == NSNotFound
            ? fullText.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive], range: NSRange(location: 0, length: fullText.length))
            : firstPass
        guard found.location != NSNotFound else {
            searchResultText = String(localized: "No matches")
            return
        }
        let direction: FloatingReaderPageDirection = found.location >= offset ? .forward : .backward
        offset = found.location
        refreshPage(animated: true, direction: direction)
        saveProgress()
        searchResultText = String(localized: "Match found")
    }

    func syncProgressFromOffice(bookID updatedBookID: UUID) {
        guard updatedBookID == bookID,
              let locator = try? ReadingProgressRepository(context: context).fetchLocator(bookID: updatedBookID) else { return }
        let previousOffset = offset
        restore(locator)
        guard offset != previousOffset else { return }
        refreshPage(animated: true, direction: offset >= previousOffset ? .forward : .backward)
        reloadBookmarks()
    }

    func applyDensity(_ density: FloatingReaderDensity) {
        self.density = density
        defaults.set(density.rawValue, forKey: Keys.density)
        fontSize = density.fontSize
        lineSpacing = density.lineSpacing
    }

    nonisolated private static func prepare(document: BookDocument, format: BookFormat) -> PreparedDocument {
        var cursor = 0
        var textParts: [String] = []
        var spans: [BlockSpan] = []
        var chapters: [FloatingReaderChapter] = []
        spans.reserveCapacity(document.chapters.reduce(0) { $0 + $1.textBlocks.count })

        for chapter in document.chapters {
            var chapterStart: Int?
            for (blockIndex, block) in chapter.textBlocks.enumerated() {
                if !textParts.isEmpty { cursor += 2 }
                chapterStart = chapterStart ?? cursor
                let length = (block.text as NSString).length
                spans.append(BlockSpan(chapterID: chapter.id, blockIndex: blockIndex, format: format, range: cursor..<(cursor + length)))
                textParts.append(block.text)
                cursor += length
            }
            if let chapterStart {
                chapters.append(FloatingReaderChapter(id: chapter.id, title: chapter.title, offset: chapterStart))
            }
        }
        return PreparedDocument(text: textParts.joined(separator: "\n\n"), spans: spans, chapters: chapters)
    }

    private func restore(_ locator: ReadingLocator?) {
        let match: (String, Int, Int)? = switch locator {
        case let .text(chapterID, blockIndex, intraBlockOffset): (chapterID, blockIndex, intraBlockOffset)
        case let .epub(spineItemID, blockIndex, intraBlockOffset): (spineItemID, blockIndex, intraBlockOffset)
        case nil: nil
        }
        guard let match,
              let span = spans.first(where: { $0.chapterID == match.0 && $0.blockIndex == match.1 }) else { return }
        let blockText = fullText.substring(with: NSRange(location: span.range.lowerBound, length: span.range.count))
        let characterIndex = blockText.index(blockText.startIndex, offsetBy: match.2, limitedBy: blockText.endIndex) ?? blockText.endIndex
        let utf16Offset = characterIndex.utf16Offset(in: blockText)
        offset = min(span.range.lowerBound + utf16Offset, max(fullText.length - 1, 0))
    }

    private func refreshPage(animated: Bool = false, direction: FloatingReaderPageDirection = .forward) {
        guard fullText.length > 0 else {
            if state == .ready { pageText = String(localized: "This record has no readable notes.") }
            progressText = String(localized: "Empty")
            progressFraction = 0
            return
        }
        offset = min(max(offset, 0), fullText.length - 1)
        let proposed = NSRange(location: offset, length: min(charactersPerPage, fullText.length - offset))
        let safeRange = fullText.rangeOfComposedCharacterSequences(for: proposed)
        pageText = fullText.substring(with: safeRange)
        let pageCount = max(1, Int(ceil(Double(fullText.length) / Double(charactersPerPage))))
        let currentPage = min(pageCount, offset / charactersPerPage + 1)
        progressText = String(format: String(localized: "Record %lld of %lld"), currentPage, pageCount)
        progressFraction = pageCount == 1 ? 1 : Double(currentPage - 1) / Double(pageCount - 1)
        isCurrentLocationBookmarked = bookmarks.contains { $0.locator == currentLocator }
        if animated {
            pageDirection = direction
            pageRevision &+= 1
        }
    }

    private func saveProgress() {
        guard let bookID, let locator = currentLocator else { return }
        guard (try? ReadingProgressRepository(context: context).save(locator: locator, for: bookID)) != nil else { return }
        ReadingProgressSync.post(bookID: bookID, source: .floatingReader)
    }

    private var currentLocator: ReadingLocator? {
        guard let span = span(containing: offset) else { return nil }
        let utf16Length = max(0, min(offset - span.range.lowerBound, span.range.count))
        let prefix = fullText.substring(with: NSRange(location: span.range.lowerBound, length: utf16Length))
        let intraBlockOffset = prefix.count
        return span.format == .epub
            ? .epub(spineItemID: span.chapterID, blockIndex: span.blockIndex, intraBlockOffset: intraBlockOffset)
            : .text(chapterID: span.chapterID, blockIndex: span.blockIndex, intraBlockOffset: intraBlockOffset)
    }

    private func reloadBookmarks() {
        guard let bookID else { bookmarks = []; isCurrentLocationBookmarked = false; return }
        bookmarks = (try? ReadingBookmarkRepository(context: context).bookmarks(for: bookID)) ?? []
        isCurrentLocationBookmarked = bookmarks.contains { $0.locator == currentLocator }
    }

    private func span(containing position: Int) -> BlockSpan? {
        spans.first(where: { $0.range.contains(position) })
            ?? spans.last(where: { $0.range.lowerBound <= position })
    }
}
