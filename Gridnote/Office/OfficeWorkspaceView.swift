import Foundation
import SwiftData
import SwiftUI

struct OfficeWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View { OfficeWorkspaceContent(context: modelContext) }
}

private struct OfficeWorkspaceContent: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var stealthController: StealthOverlayController
    @StateObject private var viewModel: OfficeWorkspaceViewModel
    @State private var isImporterPresented = false
    @State private var importMessage: String?
    @State private var didHandleLaunchFixture = false
    @State private var isUtilityControlsHovered = false
    @State private var isFindBarPresented = false
    @State private var findQuery = ""
    @State private var findMessage = ""
    @State private var actionStatus = ""
    @State private var formulaMaskTask: Task<Void, Never>?
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        _viewModel = StateObject(wrappedValue: OfficeWorkspaceViewModel(context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            officeToolbar
            formulaBar
            if isFindBarPresented { findBar }
            spreadsheet
            sheetBar
            statusBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.96, green: 0.97, blue: 0.95))
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: ImportService.supportedContentTypes, allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            do {
                let record = try ImportService(context: context).importFile(from: url)
                appState.selectedBookID = record.id
                viewModel.load(bookID: record.id)
                importMessage = String(localized: "Book imported")
            } catch { importMessage = String(localized: "Import failed") }
        }
        .alert("Import", isPresented: Binding(get: { importMessage != nil }, set: { if !$0 { importMessage = nil } })) {
            Button("OK", role: .cancel) { importMessage = nil }
        } message: { Text(importMessage ?? "") }
        .task(id: appState.selectedBookID) {
            handleLaunchFixtureIfNeeded()
            viewModel.load(bookID: appState.selectedBookID)
            writeReadyMarkerIfRequested()
            scheduleFormulaMask()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridnotePrivacyShieldRequested)) { _ in
            formulaMaskTask?.cancel()
            viewModel.concealExcerpt()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteReaderSettingsDidChange)) { _ in
            viewModel.reloadReaderPresentation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteOfficePreviousExcerptRequested)) { _ in
            previousExcerpt()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteOfficeNextExcerptRequested)) { _ in
            nextExcerpt()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteOfficeSearchRequested)) { _ in
            isFindBarPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteOfficeBookmarkRequested)) { _ in
            guard let isAdded = viewModel.toggleBookmark() else { return }
            actionStatus = isAdded ? "已添加标记" : "已取消标记"
        }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteOfficePrivacySettingsDidChange)) { _ in
            formulaMaskTask?.cancel()
            if OfficeFormulaMaskSettings.isEnabled {
                scheduleFormulaMask()
            } else {
                viewModel.revealExcerpt()
            }
        }
        .onDisappear { formulaMaskTask?.cancel() }
    }

    private var officeToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: "line.3.horizontal")
                Text("文件").fontWeight(.medium)
                Divider().frame(height: 20)
                ForEach(["square.and.arrow.down", "printer", "doc.on.doc", "arrow.uturn.left", "arrow.uturn.right"], id: \.self) { symbol in
                    Image(systemName: symbol).foregroundStyle(.secondary)
                }
                Divider().frame(height: 20)
                Text("设备租赁数据分析.xlsx")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 16)
                HStack(spacing: 28) {
                    ForEach(["开始", "插入", "页面", "公式", "数据", "审阅", "视图", "工具"], id: \.self) { title in
                        Text(title)
                            .font(.system(size: 14, weight: title == "开始" ? .semibold : .medium))
                            .foregroundStyle(title == "开始" ? Color(red: 0.02, green: 0.52, blue: 0.31) : .primary)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(title == "开始" ? Color(red: 0.02, green: 0.52, blue: 0.31) : .clear).frame(height: 2).offset(y: 11)
                            }
                    }
                }
                Spacer(minLength: 16)
                Label("已保存", systemImage: "checkmark.icloud")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Color(red: 0.96, green: 0.96, blue: 0.95))

            HStack(spacing: 0) {
                ribbonGroup("剪贴板", items: [("doc.on.clipboard", "粘贴"), ("scissors", "剪切")])
                ribbonGroup("字体", items: [("textformat", "宋体"), ("bold", "加粗"), ("textformat.size", "字号")])
                ribbonGroup("对齐", items: [("text.alignleft", "左对齐"), ("text.aligncenter", "居中"), ("rectangle.3.group", "合并")])
                ribbonGroup("数字", items: [("percent", "百分比"), ("yensign", "货币"), ("number", "常规")])
                ribbonGroup("数据", items: [("arrow.up.arrow.down", "排序"), ("line.3.horizontal.decrease.circle", "筛选"), ("tablecells", "条件格式")])
                Spacer(minLength: 10)
                utilityControls
                    .padding(.trailing, 18)
            }
            .frame(height: 82)
            .background(.white)
            .overlay(alignment: .bottom) { Divider() }
        }
        .accessibilityIdentifier("office-workspace")
    }

    private func ribbonGroup(_ title: String, items: [(String, String)]) -> some View {
        HStack(spacing: 10) {
            ForEach(items, id: \.0) { symbol, label in
                VStack(spacing: 5) {
                    Image(systemName: symbol).font(.system(size: 16, weight: .medium))
                    Text(label).font(.system(size: 10))
                }
                .foregroundStyle(.primary.opacity(0.78))
            }
        }
        .frame(minWidth: 102, minHeight: 56)
        .padding(.horizontal, 14)
        .overlay(alignment: .trailing) { Divider().frame(height: 58) }
        .overlay(alignment: .bottom) {
            Text(title).font(.system(size: 9)).foregroundStyle(.tertiary).offset(y: 9)
        }
        .allowsHitTesting(false)
    }

    private var utilityControls: some View {
        HStack(spacing: 11) {
            Button(action: previousExcerpt) { Image(systemName: "chevron.left") }
                .help("Previous Text (F7 by default)")
                .accessibilityIdentifier("office-excerpt-previous")
            Button(action: nextExcerpt) { Image(systemName: "chevron.right") }
                .help("Next Text (F8 by default)")
                .accessibilityIdentifier("office-excerpt-next")
            Button { isImporterPresented = true } label: { Image(systemName: "square.and.arrow.down") }
                .help("Import Book")
                .accessibilityIdentifier("import-book")
            Button { stealthController.show(bookID: appState.selectedBookID) } label: { Image(systemName: "rectangle.on.rectangle") }
                .help("Floating Reader")
                .accessibilityIdentifier("open-reader")
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.primary.opacity(isUtilityControlsHovered ? 0.72 : 0.28))
        .onHover { isUtilityControlsHovered = $0 }
    }

    private var formulaBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.selected.name).font(.system(.body, design: .monospaced)).frame(width: 84)
            Image(systemName: "chevron.down").font(.caption2).foregroundStyle(.secondary)
            Divider()
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            Text("fx").font(.system(size: 18, weight: .medium, design: .serif)).italic().foregroundStyle(.secondary)
            Divider()
            Group {
                if viewModel.hasFormulaExcerpt {
                    Text(viewModel.formulaBarValue)
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(viewModel.readerTextColor.opacity(viewModel.readerTextOpacity))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .onTapGesture { revealFormulaBar() }
                } else {
                    TextField("Cell value", text: Binding(get: { viewModel.selectedValue }, set: { viewModel.updateSelectedValue($0) }))
                        .textFieldStyle(.plain)
                        .accessibilityIdentifier("formula-bar")
                        .onSubmit { viewModel.commitSelectedValue() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            utilityControls
        }
        .padding(.horizontal, 12).frame(height: 62)
        .background(.white)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var findBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("查找内容", text: $findQuery)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .onSubmit { find(.next) }
            Button("上一个") { find(.previous) }
                .buttonStyle(.bordered)
            Button("下一个") { find(.next) }
                .buttonStyle(.borderedProminent)
            Text(findMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button { isFindBarPresented = false } label: { Image(systemName: "xmark") }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("关闭查找")
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Color(red: 0.98, green: 0.99, blue: 0.98))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func find(_ direction: OfficeExcerptSearchDirection) {
        let isMatch = viewModel.searchExcerpt(for: findQuery, direction: direction)
        findMessage = isMatch ? "已定位到匹配项" : "未找到匹配项"
        if isMatch { scheduleFormulaMask() }
    }

    private func previousExcerpt() {
        viewModel.previousExcerpt()
        scheduleFormulaMask()
    }

    private func nextExcerpt() {
        viewModel.nextExcerpt()
        scheduleFormulaMask()
    }

    private func revealFormulaBar() {
        viewModel.revealExcerpt()
        scheduleFormulaMask()
    }

    private func scheduleFormulaMask() {
        formulaMaskTask?.cancel()
        guard OfficeFormulaMaskSettings.isEnabled, viewModel.hasFormulaExcerpt else { return }
        let delay = OfficeFormulaMaskSettings.delay
        formulaMaskTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            viewModel.concealExcerpt()
        }
    }

    private var spreadsheet: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                HStack(spacing: 0) {
                    headerCell("").frame(width: 44)
                    ForEach(0..<OfficeGridSnapshot.columnCount, id: \.self) { column in
                        headerCell(OfficeCellCoordinate.columnName(column)).frame(width: columnWidth(column))
                    }
                }
                ForEach(0..<OfficeGridSnapshot.rowCount, id: \.self) { row in
                    HStack(spacing: 0) {
                        headerCell("\(row + 1)").frame(width: 44, height: rowHeight(row))
                        ForEach(0..<OfficeGridSnapshot.columnCount, id: \.self) { column in
                            officeCell(OfficeCellCoordinate(row: row, column: column), height: rowHeight(row))
                        }
                    }
                }
            }
        }
        .background(.white)
        .accessibilityIdentifier("office-grid")
        .accessibilityHidden(true)
    }

    private func headerCell(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.92, green: 0.94, blue: 0.91)).border(.gray.opacity(0.25), width: 0.5)
    }

    private func officeCell(_ coordinate: OfficeCellCoordinate, height: CGFloat) -> some View {
        Text(viewModel.displayValue(at: coordinate))
            .lineLimit(1)
            .multilineTextAlignment(coordinate.row == 0 ? .center : .leading)
            .font(.system(size: coordinate.row == 0 ? 11 : 11, weight: coordinate.row == 0 ? .medium : .regular))
            .foregroundStyle(coordinate.row == 0 ? .white : Color(red: 0.13, green: 0.17, blue: 0.21))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 7)
            .frame(width: columnWidth(coordinate.column), height: height)
            .background(cellBackground(for: coordinate))
            .overlay(Rectangle().stroke(coordinate == viewModel.selected ? Color(red: 0.02, green: 0.52, blue: 0.31) : Color.gray.opacity(0.22), lineWidth: coordinate == viewModel.selected ? 2 : 0.5))
            .onTapGesture { viewModel.select(coordinate) }
            .help("Select the cell and edit its value in the formula bar")
    }

    private func columnWidth(_ column: Int) -> CGFloat {
        let widths: [CGFloat] = [112, 120, 82, 118, 158, 70, 108, 98, 126, 126, 98, 96, 82, 112, 112, 112, 112, 98]
        return widths.indices.contains(column) ? widths[column] : 110
    }

    private func rowHeight(_ row: Int) -> CGFloat {
        row == 0 ? 30 : 27
    }

    private func cellBackground(for coordinate: OfficeCellCoordinate) -> Color {
        if coordinate.row == 0 { return Color(red: 0.26, green: 0.36, blue: 0.47) }
        if coordinate == viewModel.selected { return Color(red: 0.85, green: 0.93, blue: 0.88) }
        return coordinate.row.isMultiple(of: 2) ? Color(red: 0.92, green: 0.94, blue: 0.95) : Color(red: 0.97, green: 0.98, blue: 0.98)
    }

    private var sheetBar: some View {
        HStack(spacing: 0) {
            Button(action: {}) { Image(systemName: "plus") }.buttonStyle(.plain).padding(.horizontal, 14)
            Text(viewModel.sheetName).font(.callout).fontWeight(.medium).padding(.horizontal, 20).frame(height: 32)
                .background(.white).overlay(alignment: .bottom) { Rectangle().fill(Color.green).frame(height: 2) }
            Spacer()
        }.background(Color(red: 0.91, green: 0.93, blue: 0.90))
    }

    private var statusBar: some View {
        HStack {
            Text(actionStatus.isEmpty ? "Ready" : actionStatus)
            Spacer()
            Text("Selected: \(viewModel.selected.name)")
            Divider().frame(height: 14)
            Text("100%")
        }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12).frame(height: 26).background(Color(red: 0.94, green: 0.95, blue: 0.93))
    }

    private func handleLaunchFixtureIfNeeded() {
        guard !didHandleLaunchFixture else { return }
        didHandleLaunchFixture = true
        guard let path = ProcessInfo.processInfo.environment["GRIDNOTE_TEST_IMPORT_PATH"] else { return }
        do {
            let url = URL(fileURLWithPath: path)
            let repository = BookRepository(context: context)
            let record = try repository.fetch(sourcePath: url.path) ?? repository.insert(metadata: .init(title: url.deletingPathExtension().lastPathComponent, sourceFilename: url.lastPathComponent), sourcePath: url.path, format: ImportService.detectFormat(for: url))
            if ProcessInfo.processInfo.environment["GRIDNOTE_TEST_SOURCE_MISSING"] == "1" {
                record.sourceStatus = .missing
                try context.save()
            }
            appState.selectedBookID = record.id
        } catch { importMessage = String(localized: "Import failed") }
    }

    private func writeReadyMarkerIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["GRIDNOTE_TEST_READY_MARKER"] else { return }
        FileManager.default.createFile(atPath: path, contents: Data("ready".utf8))
    }
}

enum OfficeExcerptSearchDirection {
    case previous
    case next
}

enum OfficeFormulaMaskSettings {
    static let delayRange: ClosedRange<Double> = 3...30
    static let defaultDelay = 8.0
    private static let enabledKey = "officePrivacy.autoMaskFormulaBar"
    private static let delayKey = "officePrivacy.formulaBarMaskDelay"

    static func isEnabled(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: enabledKey) as? Bool ?? true
    }

    static func delay(in defaults: UserDefaults = .standard) -> Double {
        min(max(defaults.object(forKey: delayKey) as? Double ?? defaultDelay, delayRange.lowerBound), delayRange.upperBound)
    }

    static var isEnabled: Bool { isEnabled(in: .standard) }
    static var delay: Double { delay(in: .standard) }

    static func save(enabled: Bool, delay: Double, to defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: enabledKey)
        defaults.set(min(max(delay, delayRange.lowerBound), delayRange.upperBound), forKey: delayKey)
    }
}

enum OfficeExcerptSearch {
    static func matchingBlockIndex(
        in blocks: [TextBlock],
        query: String,
        currentIndex: Int,
        direction: OfficeExcerptSearchDirection
    ) -> Int? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !blocks.isEmpty else { return nil }
        let currentIndex = min(max(currentIndex, 0), blocks.count - 1)
        let indices: [Int]
        switch direction {
        case .next:
            indices = Array((currentIndex + 1)..<blocks.count) + Array(0...currentIndex)
        case .previous:
            indices = Array(stride(from: currentIndex - 1, through: 0, by: -1)) + Array(stride(from: blocks.count - 1, through: currentIndex, by: -1))
        }
        return indices.first {
            blocks[$0].text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}

@MainActor
final class OfficeWorkspaceViewModel: ObservableObject {
    @Published private(set) var snapshot = OfficeGridSnapshot.defaultOperations
    @Published private(set) var selected = OfficeCellCoordinate(row: 0, column: 0)
    @Published private(set) var sheetName = "5_明细数据"
    @Published private var editorValue = ""
    @Published private(set) var isExcerptConcealed = false
    @Published private(set) var readerTextColor = ReaderPresentationSettings.textColor
    @Published private(set) var readerTextOpacity = ReaderPresentationSettings.textOpacity
    private let context: ModelContext
    private var record: OfficeSheetRecord?
    private var excerptBlocks: [TextBlock] = []
    private var excerpt = InjectedExcerpt(startBlockIndex: 0, valuesByRow: [:], nextBlockIndex: nil)
    private var excerptBookID: UUID?
    private var excerptFormat: BookFormat?
    private var excerptChapters: [ExcerptChapterIndex] = []

    init(context: ModelContext) { self.context = context }

    var selectedValue: String { editorValue }
    func value(at coordinate: OfficeCellCoordinate) -> String { snapshot[coordinate] }
    func displayValue(at coordinate: OfficeCellCoordinate) -> String { snapshot[coordinate] }
    var hasFormulaExcerpt: Bool { excerpt.valuesByRow[1] != nil }
    var formulaBarValue: String {
        guard let excerpt = excerpt.valuesByRow[1] else { return editorValue }
        return isExcerptConcealed ? OfficeExcerptMasker.value(forRow: 1) : excerpt
    }
    func select(_ coordinate: OfficeCellCoordinate) {
        commitSelectedValue()
        selected = coordinate
        editorValue = displayValue(at: coordinate)
        persist()
    }
    func setValue(_ value: String, at coordinate: OfficeCellCoordinate) { selected = coordinate; snapshot[coordinate] = value; persist() }
    func updateSelectedValue(_ value: String) { editorValue = value }
    func commitSelectedValue() { snapshot[selected] = editorValue; persist() }

    func reloadReaderPresentation() {
        readerTextColor = ReaderPresentationSettings.textColor
        readerTextOpacity = ReaderPresentationSettings.textOpacity
    }

    func load(bookID: UUID?) {
        do {
            let repository = OfficeSheetRepository(context: context)
            let record = try repository.fetchOrCreate(bookID: bookID)
            self.record = record
            snapshot = repository.snapshot(from: record)
            selected = OfficeCellCoordinate(row: record.selectedRow, column: record.selectedColumn)
            editorValue = snapshot[selected]
            sheetName = record.activeSheetName == "Overview" ? "5_明细数据" : record.activeSheetName
            loadExcerpt(bookID: bookID)
        } catch {}
    }

    func nextExcerpt() {
        revealExcerpt()
        guard let next = excerpt.nextBlockIndex else { return }
        applyExcerpt(startingAt: next)
    }

    func previousExcerpt() {
        revealExcerpt()
        applyExcerpt(startingAt: max(excerpt.startBlockIndex - 1, 0))
    }

    func concealExcerpt() {
        guard !isExcerptConcealed else { return }
        isExcerptConcealed = true
    }

    func revealExcerpt() {
        guard isExcerptConcealed else { return }
        isExcerptConcealed = false
    }

    @discardableResult
    func searchExcerpt(for query: String, direction: OfficeExcerptSearchDirection) -> Bool {
        guard let match = OfficeExcerptSearch.matchingBlockIndex(
            in: excerptBlocks,
            query: query,
            currentIndex: excerpt.startBlockIndex,
            direction: direction
        ) else { return false }
        revealExcerpt()
        applyExcerpt(startingAt: match)
        return true
    }

    @discardableResult
    func toggleBookmark() -> Bool? {
        guard let excerptBookID,
              let locator = locator(forGlobalBlockIndex: excerpt.startBlockIndex),
              let excerpt = excerpt.valuesByRow[1]
        else { return nil }
        return try? ReadingBookmarkRepository(context: context).toggle(
            bookID: excerptBookID,
            locator: locator,
            excerpt: excerpt.replacingOccurrences(of: "\n", with: " ").prefix(72).description
        )
    }

    private func persist() {
        guard let record else { return }
        try? OfficeSheetRepository(context: context).save(snapshot: snapshot, selected: selected, sheetName: sheetName, to: record)
    }

    private func loadExcerpt(bookID: UUID?) {
        excerptBookID = bookID
        excerptBlocks = []
        excerptChapters = []
        isExcerptConcealed = false
        guard let bookID, let book = try? BookRepository(context: context).fetch(id: bookID) else {
            excerpt = InjectedExcerpt(startBlockIndex: 0, valuesByRow: [:], nextBlockIndex: nil)
            return
        }
        do {
            let url = URL(fileURLWithPath: book.sourcePath)
            switch book.format {
            case .txt:
                let document = try TXTParser(cacheStore: TextParseCacheStore()).parse(url: url, metadata: book.metadata, id: book.id)
                configureExcerptDocument(document)
            case .epub:
                let document = try EPUBParser(cacheStore: TextParseCacheStore()).parse(url: url, metadata: book.metadata, id: book.id)
                configureExcerptDocument(document)
            }
            excerptFormat = book.format
            let locator = try ReadingProgressRepository(context: context).fetchLocator(bookID: bookID)
            let start: Int
            switch locator {
            case let .text(chapterID, blockIndex, _), let .epub(chapterID, blockIndex, _):
                start = ExcerptPositionMapper.globalBlockIndex(
                    chapterID: chapterID,
                    blockIndex: blockIndex,
                    chapters: excerptChapters,
                    totalBlockCount: excerptBlocks.count
                )
            default: start = 0
            }
            applyExcerpt(startingAt: start)
        } catch {
            excerpt = InjectedExcerpt(startBlockIndex: 0, valuesByRow: [:], nextBlockIndex: nil)
        }
    }

    private func applyExcerpt(startingAt index: Int) {
        excerpt = ExcerptInjector.inject(blocks: excerptBlocks, startBlockIndex: index, rowCount: 1)
        objectWillChange.send()
        guard let excerptBookID,
              let locator = locator(forGlobalBlockIndex: excerpt.startBlockIndex) else { return }
        _ = try? ReadingProgressRepository(context: context).save(locator: locator, for: excerptBookID)
    }

    private func locator(forGlobalBlockIndex index: Int) -> ReadingLocator? {
        guard let location = ExcerptPositionMapper.location(forGlobalBlockIndex: index, chapters: excerptChapters) else { return nil }
        return excerptFormat == .epub
            ? .epub(spineItemID: location.chapterID, blockIndex: location.blockIndex, intraBlockOffset: 0)
            : .text(chapterID: location.chapterID, blockIndex: location.blockIndex, intraBlockOffset: 0)
    }

    private func configureExcerptDocument(_ document: BookDocument) {
        var offset = 0
        excerptChapters = document.chapters.map { chapter in
            defer { offset += chapter.textBlocks.count }
            return ExcerptChapterIndex(id: chapter.id, startBlockIndex: offset)
        }
        excerptBlocks = document.chapters.flatMap(\.textBlocks)
    }
}
