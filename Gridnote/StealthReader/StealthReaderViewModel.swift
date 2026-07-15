import AppKit
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

enum ReaderFontFamily: String, CaseIterable, Identifiable {
    case system
    case rounded
    case serif
    case monospaced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "系统"
        case .rounded: "圆体"
        case .serif: "宋体"
        case .monospaced: "等宽"
        }
    }

    var design: Font.Design {
        switch self {
        case .system: .default
        case .rounded: .rounded
        case .serif: .serif
        case .monospaced: .monospaced
        }
    }
}

enum ReaderFontWeight: String, CaseIterable, Identifiable {
    case regular
    case medium
    case semibold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .regular: "常规"
        case .medium: "中等"
        case .semibold: "半粗"
        }
    }

    var swiftUIWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        }
    }

    var appKitWeight: NSFont.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
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

struct FloatingReaderPageLayout: Equatable {
    let range: NSRange
    let measuredWidth: CGFloat
    let nextOffset: Int?
}

enum FloatingReaderPaginator {
    private static let semanticBreaks = CharacterSet(charactersIn: "。！？!?；;，,\n\r")

    static func singleLineLayout(
        text: NSString,
        start: Int,
        maximumWidth: CGFloat,
        font: NSFont,
        letterSpacing: CGFloat = 0
    ) -> FloatingReaderPageLayout {
        guard text.length > 0 else { return .init(range: NSRange(location: 0, length: 0), measuredWidth: 0, nextOffset: nil) }
        let safeStart = min(max(start, 0), text.length - 1)
        let remaining = text.length - safeStart
        var low = 1
        var high = remaining
        var fittedLength = 1

        while low <= high {
            let middle = (low + high) / 2
            let candidate = text.rangeOfComposedCharacterSequences(for: NSRange(location: safeStart, length: middle))
            if measuredWidth(of: text, range: candidate, font: font, letterSpacing: letterSpacing) <= maximumWidth {
                fittedLength = candidate.length
                low = middle + 1
            } else {
                high = middle - 1
            }
        }

        var range = text.rangeOfComposedCharacterSequences(for: NSRange(location: safeStart, length: fittedLength))
        if range.location + range.length < text.length, let semanticLength = semanticLength(in: text, range: range) {
            range.length = semanticLength
        }
        let width = measuredWidth(of: text, range: range, font: font, letterSpacing: letterSpacing)
        let end = range.location + range.length
        let nextOffset = end < text.length ? end : nil
        return .init(range: range, measuredWidth: width, nextOffset: nextOffset)
    }

    private static func semanticLength(in text: NSString, range: NSRange) -> Int? {
        let minimumLength = max(8, Int(Double(range.length) * 0.62))
        guard range.length > minimumLength else { return nil }
        for index in stride(from: range.location + range.length - 1, through: range.location + minimumLength - 1, by: -1) {
            let scalar = UnicodeScalar(text.character(at: index))
            if scalar.map(semanticBreaks.contains) == true { return index - range.location + 1 }
        }
        return nil
    }

    private static func measuredWidth(of text: NSString, range: NSRange, font: NSFont, letterSpacing: CGFloat) -> CGFloat {
        let display = text.substring(with: range)
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return ceil(NSAttributedString(string: display, attributes: [.font: font, .kern: letterSpacing]).size().width)
    }

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
    @Published private(set) var searchContext = ""
    @Published private(set) var progressDetailText = ""
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
        didSet {
            defaults.set(lineSpacing, forKey: Keys.lineSpacing)
            refreshPage()
        }
    }
    @Published var letterSpacing: Double {
        didSet {
            defaults.set(letterSpacing, forKey: Keys.letterSpacing)
            refreshPage()
        }
    }
    @Published var fontFamily: ReaderFontFamily {
        didSet {
            defaults.set(fontFamily.rawValue, forKey: Keys.fontFamily)
            singleLineFont = nil
        }
    }
    @Published var fontWeight: ReaderFontWeight {
        didSet {
            defaults.set(fontWeight.rawValue, forKey: Keys.fontWeight)
            singleLineFont = nil
        }
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
        static let letterSpacing = "stealthReader.letterSpacing"
        static let fontFamily = "stealthReader.fontFamily"
        static let fontWeight = "stealthReader.fontWeight"
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
    private var nextPageOffset: Int?
    private var previousPageOffsets: [Int] = []
    private var singleLineMaximumWidth: CGFloat?
    private var singleLineFont: NSFont?
    private var bookID: UUID?
    private var isReloadingPresentation = false
    private var searchMatches: [NSRange] = []
    private var selectedSearchMatchIndex: Int?
    private var activeSearchQuery = ""

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
        letterSpacing = min(max(defaults.object(forKey: Keys.letterSpacing) as? Double ?? 0, -0.5), 2)
        fontFamily = ReaderFontFamily(rawValue: defaults.string(forKey: Keys.fontFamily) ?? "") ?? .rounded
        fontWeight = ReaderFontWeight(rawValue: defaults.string(forKey: Keys.fontWeight) ?? "") ?? .regular
        backgroundOpacity = min(max(defaults.object(forKey: Keys.backgroundOpacity) as? Double ?? 0.94, 0), 1)
        textColor = ReaderPresentationSettings.textColor(in: self.presentationDefaults)
        textOpacity = ReaderPresentationSettings.textOpacity(in: self.presentationDefaults)
        appearance = StealthAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .activity
        density = FloatingReaderDensity(rawValue: defaults.string(forKey: Keys.density) ?? "") ?? .balanced
    }

    var canGoPrevious: Bool { offset > 0 }
    var canGoNext: Bool {
        singleLineMaximumWidth == nil
            ? offset + charactersPerPage < fullText.length
            : nextPageOffset != nil
    }
    var currentPageMeasuredWidth: CGFloat {
        guard let font = singleLineFont else { return 0 }
        return FloatingReaderPaginator.singleLineLayout(
            text: fullText,
            start: offset,
            maximumWidth: singleLineMaximumWidth ?? .greatestFiniteMagnitude,
            font: font,
            letterSpacing: letterSpacing
        ).measuredWidth
    }

    func reloadPresentationSettings() {
        isReloadingPresentation = true
        defer { isReloadingPresentation = false }
        textColor = ReaderPresentationSettings.textColor(in: presentationDefaults)
        textOpacity = ReaderPresentationSettings.textOpacity(in: presentationDefaults)
    }

    func load(bookID requestedBookID: UUID?) async {
        state = .loading
        chapters = []
        clearSearch()
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
        previousPageOffsets.append(offset)
        offset = nextPageOffset ?? min(offset + charactersPerPage, max(fullText.length - 1, 0))
        refreshPage(animated: true, direction: .forward)
        saveProgress()
    }

    func previous() {
        guard canGoPrevious else { return }
        offset = previousPageOffsets.popLast() ?? max(offset - charactersPerPage, 0)
        refreshPage(animated: true, direction: .backward)
        saveProgress()
    }

    func seek(to fraction: Double) {
        guard fullText.length > 0 else { return }
        let rawOffset = Int(Double(max(fullText.length - 1, 0)) * min(max(fraction, 0), 1))
        let direction: FloatingReaderPageDirection = rawOffset >= offset ? .forward : .backward
        offset = rawOffset - rawOffset % charactersPerPage
        previousPageOffsets.removeAll()
        refreshPage(animated: true, direction: direction)
        saveProgress()
    }

    /// Keeps each page inside the current floating panel instead of relying on vertical scrolling.
    func fitPage(to size: CGSize, maximumLines: Int? = nil) {
        if maximumLines == nil {
            singleLineMaximumWidth = nil
            singleLineFont = nil
        }
        let usableWidth = max(size.width - 32, 120)
        let usableHeight = max(size.height - (maximumLines == nil ? 26 : 8), 16)
        // CJK glyphs are approximately one em wide. Using a narrower average here
        // causes SwiftUI to truncate the final glyphs in one-line stealth mode.
        let estimatedCharacterWidth = maximumLines == nil
            ? max(fontSize * 0.98 + max(letterSpacing, 0), 8)
            : max(fontSize * 1.08, 8)
        let estimatedLineHeight = max(fontSize + lineSpacing + 8, 17)
        let charactersPerLine = max(8, Int(usableWidth / estimatedCharacterWidth))
        let fittedLines = max(1, Int(usableHeight / estimatedLineHeight))
        let visibleLines = maximumLines.map { min(fittedLines, max($0, 1)) } ?? max(2, fittedLines - 1)
        let minimumCapacity = maximumLines == nil ? 80 : 8
        let fittedCapacity = min(max(charactersPerLine * visibleLines, minimumCapacity), 1600)

        guard fittedCapacity != charactersPerPage else { return }
        charactersPerPage = fittedCapacity
    }

    func fitSingleLinePage(maximumTextWidth: CGFloat, monospaced: Bool) {
        let width = max(maximumTextWidth, 120)
        let family = monospaced ? ReaderFontFamily.monospaced : fontFamily
        let font = readerFont(family: family)
        guard singleLineMaximumWidth != width || singleLineFont != font else { return }
        singleLineMaximumWidth = width
        singleLineFont = font
        previousPageOffsets.removeAll()
        refreshPage()
    }

    func goToStart() {
        offset = 0
        previousPageOffsets.removeAll()
        refreshPage(animated: true, direction: .backward)
        saveProgress()
    }

    func jump(to chapter: FloatingReaderChapter) {
        guard fullText.length > 0 else { return }
        let direction: FloatingReaderPageDirection = chapter.offset >= offset ? .forward : .backward
        offset = min(max(chapter.offset, 0), fullText.length - 1)
        previousPageOffsets.removeAll()
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
        navigateSearch(for: query, direction: 1)
    }

    func searchPrevious(for query: String) {
        navigateSearch(for: query, direction: -1)
    }

    func clearSearch() {
        activeSearchQuery = ""
        searchMatches = []
        selectedSearchMatchIndex = nil
        searchResultText = ""
        searchContext = ""
    }

    private func navigateSearch(for query: String, direction: Int) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, fullText.length > 0 else {
            clearSearch()
            return
        }

        if activeSearchQuery.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame {
            activeSearchQuery = trimmed
            searchMatches = ranges(matching: trimmed)
            selectedSearchMatchIndex = nil
        }

        guard !searchMatches.isEmpty else {
            searchResultText = String(localized: "No matches")
            searchContext = ""
            return
        }

        let selectedIndex: Int
        if let currentIndex = selectedSearchMatchIndex {
            selectedIndex = (currentIndex + direction + searchMatches.count) % searchMatches.count
        } else if direction > 0 {
            selectedIndex = searchMatches.firstIndex(where: { $0.location >= offset }) ?? 0
        } else {
            selectedIndex = searchMatches.lastIndex(where: { $0.location < offset }) ?? (searchMatches.count - 1)
        }
        selectedSearchMatchIndex = selectedIndex
        let found = searchMatches[selectedIndex]

        let contextStart = max(0, found.location - 24)
        let contextEnd = min(fullText.length, found.location + found.length + 32)
        let contextRange = fullText.rangeOfComposedCharacterSequences(
            for: NSRange(location: contextStart, length: contextEnd - contextStart)
        )
        searchContext = fullText.substring(with: contextRange)
            .replacingOccurrences(of: "\n", with: " ")
        let direction: FloatingReaderPageDirection = found.location >= offset ? .forward : .backward
        offset = found.location
        previousPageOffsets.removeAll()
        refreshPage(animated: true, direction: direction)
        saveProgress()
        searchResultText = String(
            format: String(localized: "Result %lld of %lld"),
            Int64(selectedIndex + 1),
            Int64(searchMatches.count)
        )
    }

    private func ranges(matching query: String) -> [NSRange] {
        var matches: [NSRange] = []
        var searchLocation = 0
        while searchLocation < fullText.length {
            let range = NSRange(location: searchLocation, length: fullText.length - searchLocation)
            let match = fullText.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], range: range)
            guard match.location != NSNotFound, match.length > 0 else { break }
            matches.append(match)
            searchLocation = match.location + match.length
        }
        return matches
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
        let safeRange: NSRange
        if let width = singleLineMaximumWidth, let font = singleLineFont {
            let layout = FloatingReaderPaginator.singleLineLayout(
                text: fullText,
                start: offset,
                maximumWidth: width,
                font: font,
                letterSpacing: letterSpacing
            )
            safeRange = layout.range
            nextPageOffset = layout.nextOffset
        } else {
            let proposed = NSRange(location: offset, length: min(charactersPerPage, fullText.length - offset))
            safeRange = fullText.rangeOfComposedCharacterSequences(for: proposed)
            nextPageOffset = safeRange.location + safeRange.length < fullText.length
                ? safeRange.location + safeRange.length
                : nil
        }
        pageText = fullText.substring(with: safeRange)
        let effectivePageLength = max(safeRange.length, 1)
        let pageCount = max(1, Int(ceil(Double(fullText.length) / Double(effectivePageLength))))
        let currentPage = min(pageCount, offset / effectivePageLength + 1)
        progressText = String(format: String(localized: "Record %lld of %lld"), currentPage, pageCount)
        progressFraction = fullText.length <= 1
            ? 1
            : Double(offset) / Double(fullText.length - 1)
        let chapter = chapters.last(where: { $0.offset <= offset })?.title ?? "正文"
        progressDetailText = "\(chapter) · \(String(format: "%.1f", progressFraction * 100))%"
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

    private func readerFont(family: ReaderFontFamily) -> NSFont {
        switch family {
        case .monospaced:
            .monospacedSystemFont(ofSize: fontSize, weight: fontWeight.appKitWeight)
        case .serif:
            NSFont(descriptor: NSFont.systemFont(ofSize: fontSize).fontDescriptor.withDesign(.serif) ?? NSFont.systemFont(ofSize: fontSize).fontDescriptor, size: fontSize)
                ?? .systemFont(ofSize: fontSize, weight: fontWeight.appKitWeight)
        case .rounded:
            NSFont(descriptor: NSFont.systemFont(ofSize: fontSize).fontDescriptor.withDesign(.rounded) ?? NSFont.systemFont(ofSize: fontSize).fontDescriptor, size: fontSize)
                ?? .systemFont(ofSize: fontSize, weight: fontWeight.appKitWeight)
        case .system:
            .systemFont(ofSize: fontSize, weight: fontWeight.appKitWeight)
        }
    }
}
