import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ReaderViewModel: ObservableObject {
    enum ReaderState: Equatable { case empty, loading, ready, failed(String) }

    private struct BlockReference {
        let chapterID: String
        let blockIndex: Int
        let text: String
    }

    @Published private(set) var state: ReaderState = .empty
    @Published private(set) var title = String(localized: "No Book Open")
    @Published private(set) var currentText = String(localized: "Import a TXT book from the office workspace.")
    @Published private(set) var progressText = String(localized: "No progress")
    @Published private(set) var progressFraction = 0.0
    @Published private(set) var bookmarks: [ReadingBookmark] = []
    @Published private(set) var isCurrentLocationBookmarked = false
    @Published private(set) var searchResultText = ""
    @Published var fontSize: Double = 18
    @Published private(set) var lineHeight: Double = 8
    @Published private(set) var theme = "system"
    @Published private(set) var format: BookFormat?
    @Published var textColor: Color { didSet { ReaderPresentationSettings.save(color: textColor, opacity: textOpacity) } }
    @Published var textOpacity: Double { didSet { ReaderPresentationSettings.save(color: textColor, opacity: textOpacity) } }

    private let context: ModelContext
    private var bookID: UUID?
    private var blocks: [BlockReference] = []
    private var currentBlockIndex = 0

    init(context: ModelContext) {
        self.context = context
        textColor = ReaderPresentationSettings.textColor
        textOpacity = ReaderPresentationSettings.textOpacity
    }

    var canGoPrevious: Bool { currentBlockIndex > 0 }
    var canGoNext: Bool { currentBlockIndex < blocks.count - 1 }

    func load(bookID requestedBookID: UUID?) {
        state = .loading
        do {
            let bookRepository = BookRepository(context: context)
            let record = try requestedBookID.flatMap { try bookRepository.fetch(id: $0) }
                ?? bookRepository.fetchLastOpenedOrFirst()
            guard let record else {
                state = .empty
                title = String(localized: "No Book Open")
                currentText = String(localized: "Import a TXT book from the office workspace.")
                progressText = String(localized: "No progress")
                return
            }
            let document: BookDocument = switch record.format {
            case .txt: try TXTParser(cacheStore: TextParseCacheStore()).parse(url: URL(fileURLWithPath: record.sourcePath), metadata: record.metadata, id: record.id)
            case .epub: try EPUBParser(cacheStore: TextParseCacheStore()).parse(url: URL(fileURLWithPath: record.sourcePath), metadata: record.metadata, id: record.id)
            }
            let settings = try AppSettingsRepository(context: context).fetchOrCreate()
            blocks = document.chapters.flatMap { chapter in
                chapter.textBlocks.enumerated().map { BlockReference(chapterID: chapter.id, blockIndex: $0.offset, text: $0.element.text) }
            }
            bookID = record.id
            format = record.format
            title = document.metadata.title
            fontSize = settings.standardReaderFontSize
            lineHeight = settings.standardReaderLineHeight ?? 8
            theme = settings.readerThemeRawValue
            currentBlockIndex = restoredBlockIndex(from: try ReadingProgressRepository(context: context).fetchLocator(bookID: record.id))
            record.lastOpenedAt = .now
            try context.save()
            reloadBookmarks()
            applyCurrentBlock()
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
            title = String(localized: "Reader Error")
            currentText = error.localizedDescription
            progressText = String(localized: "Unable to open book")
        }
    }

    func nextBlock() {
        guard canGoNext else { return }
        currentBlockIndex += 1
        applyCurrentBlock()
        saveProgress()
    }

    func previousBlock() {
        guard canGoPrevious else { return }
        currentBlockIndex -= 1
        applyCurrentBlock()
        saveProgress()
    }

    func seek(to fraction: Double) {
        guard !blocks.isEmpty else { return }
        currentBlockIndex = min(blocks.count - 1, max(0, Int((Double(blocks.count - 1) * min(max(fraction, 0), 1)).rounded())))
        applyCurrentBlock()
        saveProgress()
    }

    func updateFontSize(_ value: Double) {
        fontSize = value
        try? AppSettingsRepository(context: context).updateStandardReaderFontSize(value)
    }

    func reloadSettings() {
        guard let settings = try? AppSettingsRepository(context: context).fetchOrCreate() else { return }
        fontSize = settings.standardReaderFontSize
        lineHeight = settings.standardReaderLineHeight ?? 8
        theme = settings.readerThemeRawValue
        textColor = ReaderPresentationSettings.textColor
        textOpacity = ReaderPresentationSettings.textOpacity
    }

    func toggleBookmark() {
        guard let bookID, let locator = currentLocator else { return }
        _ = try? ReadingBookmarkRepository(context: context).toggle(bookID: bookID, locator: locator, excerpt: currentText.replacingOccurrences(of: "\n", with: " ").prefix(72).description)
        reloadBookmarks()
    }

    func jump(to bookmark: ReadingBookmark) {
        currentBlockIndex = restoredBlockIndex(from: bookmark.locator)
        applyCurrentBlock()
        saveProgress()
    }

    func deleteBookmark(_ bookmark: ReadingBookmark) {
        try? ReadingBookmarkRepository(context: context).delete(id: bookmark.id)
        reloadBookmarks()
    }

    func search(for query: String) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !blocks.isEmpty else { searchResultText = ""; return }
        let orderedIndices = Array((currentBlockIndex + 1)..<blocks.count) + Array(0...min(currentBlockIndex, blocks.count - 1))
        guard let found = orderedIndices.first(where: { blocks[$0].text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }) else {
            searchResultText = String(localized: "No matches")
            return
        }
        currentBlockIndex = found
        applyCurrentBlock()
        saveProgress()
        searchResultText = String(localized: "Match found")
    }

    func saveProgress() {
        guard let bookID, let locator = currentLocator else { return }
        _ = try? ReadingProgressRepository(context: context).save(locator: locator, for: bookID)
    }

    private var currentLocator: ReadingLocator? {
        guard blocks.indices.contains(currentBlockIndex), let format else { return nil }
        let block = blocks[currentBlockIndex]
        return format == .epub
            ? .epub(spineItemID: block.chapterID, blockIndex: block.blockIndex, intraBlockOffset: 0)
            : .text(chapterID: block.chapterID, blockIndex: block.blockIndex, intraBlockOffset: 0)
    }

    private func restoredBlockIndex(from locator: ReadingLocator?) -> Int {
        let match: (String, Int)? = switch locator {
        case let .text(chapterID, blockIndex, _): (chapterID, blockIndex)
        case let .epub(spineItemID, blockIndex, _): (spineItemID, blockIndex)
        case nil: nil
        }
        guard let match else { return 0 }
        return blocks.firstIndex { $0.chapterID == match.0 && $0.blockIndex == match.1 } ?? 0
    }

    private func applyCurrentBlock() {
        guard blocks.indices.contains(currentBlockIndex) else {
            currentText = String(localized: "This book has no readable text.")
            progressText = String(localized: "No progress")
            progressFraction = 0
            return
        }
        currentText = blocks[currentBlockIndex].text
        progressText = String(format: String(localized: "Paragraph %lld of %lld"), currentBlockIndex + 1, blocks.count)
        progressFraction = blocks.count <= 1 ? 1 : Double(currentBlockIndex) / Double(blocks.count - 1)
        isCurrentLocationBookmarked = bookmarks.contains { $0.locator == currentLocator }
    }

    private func reloadBookmarks() {
        guard let bookID else { bookmarks = []; isCurrentLocationBookmarked = false; return }
        bookmarks = (try? ReadingBookmarkRepository(context: context).bookmarks(for: bookID)) ?? []
        isCurrentLocationBookmarked = bookmarks.contains { $0.locator == currentLocator }
    }
}
