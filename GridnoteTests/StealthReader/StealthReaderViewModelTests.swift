import AppKit
import SwiftData
import XCTest
@testable import Gridnote

@MainActor
final class StealthReaderViewModelTests: XCTestCase {
    func testPaginatesTextAndPersistsPreciseProgress() async throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-stealth-\(UUID().uuidString).txt")
        try Data((String(repeating: "A", count: 100) + "\n\n" + String(repeating: "B", count: 100)).utf8)
            .write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let suiteName = "gridnote-stealth-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(80, forKey: "stealthReader.charactersPerPage")

        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let book = try BookRepository(context: context).insert(
            metadata: .init(title: "Stealth Fixture", sourceFilename: sourceURL.lastPathComponent),
            sourcePath: sourceURL.path,
            format: .txt
        )
        let viewModel = StealthReaderViewModel(context: context, defaults: defaults)

        await viewModel.load(bookID: book.id)
        XCTAssertEqual(viewModel.pageText.count, 80)
        XCTAssertEqual(viewModel.chapters.map(\.title), ["Stealth Fixture"])
        XCTAssertEqual(viewModel.progressText, String(format: String(localized: "Record %lld of %lld"), 1, 3))
        XCTAssertFalse(viewModel.progressDetailText.isEmpty)
        XCTAssertTrue(viewModel.canGoNext)

        viewModel.next()
        XCTAssertEqual(viewModel.pageRevision, 1)
        XCTAssertEqual(viewModel.pageDirection, .forward)
        XCTAssertEqual(viewModel.progressText, String(format: String(localized: "Record %lld of %lld"), 2, 3))
        XCTAssertEqual(viewModel.progressFraction, 80.0 / 201.0, accuracy: 0.0001)
        let locator = try XCTUnwrap(ReadingProgressRepository(context: context).fetchLocator(bookID: book.id))
        guard case let .text(_, blockIndex, intraBlockOffset) = locator else {
            return XCTFail("Expected text progress")
        }
        XCTAssertEqual(blockIndex, 0)
        XCTAssertEqual(intraBlockOffset, 80)

        viewModel.search(for: "BBBB")
        XCTAssertFalse(viewModel.searchContext.isEmpty)
        XCTAssertTrue(viewModel.searchContext.contains("BBBB"))
    }

    func testSearchReportsPositionAndAdvancesThroughEveryMatch() async throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-search-\(UUID().uuidString).txt")
        try Data("序言。目标甲。中段。目标乙。结尾。目标丙。".utf8).write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let suiteName = "gridnote-search-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let book = try BookRepository(context: context).insert(
            metadata: .init(title: "Search Fixture", sourceFilename: sourceURL.lastPathComponent),
            sourcePath: sourceURL.path,
            format: .txt
        )
        let viewModel = StealthReaderViewModel(context: context, defaults: defaults)

        await viewModel.load(bookID: book.id)
        viewModel.search(for: "目标")
        XCTAssertEqual(viewModel.searchResultText, "第 1 / 3 项")

        viewModel.search(for: "目标")
        XCTAssertEqual(viewModel.searchResultText, "第 2 / 3 项")
    }

    func testSynchronizesExternalOfficeProgressWithoutWritingItBack() async throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-progress-sync-\(UUID().uuidString).txt")
        try Data((String(repeating: "A", count: 100) + "\n\n" + String(repeating: "B", count: 100)).utf8)
            .write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let suiteName = "gridnote-progress-sync-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(80, forKey: "stealthReader.charactersPerPage")

        let container = try GridnoteModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let book = try BookRepository(context: context).insert(
            metadata: .init(title: "Progress Fixture", sourceFilename: sourceURL.lastPathComponent),
            sourcePath: sourceURL.path,
            format: .txt
        )
        let viewModel = StealthReaderViewModel(context: context, defaults: defaults)

        await viewModel.load(bookID: book.id)
        viewModel.next()
        let officeLocator = try XCTUnwrap(ReadingProgressRepository(context: context).fetchLocator(bookID: book.id))
        viewModel.goToStart()
        XCTAssertEqual(viewModel.progressText, String(format: String(localized: "Record %lld of %lld"), 1, 3))

        try ReadingProgressRepository(context: context).save(locator: officeLocator, for: book.id)
        viewModel.syncProgressFromOffice(bookID: book.id)

        XCTAssertEqual(viewModel.progressText, String(format: String(localized: "Record %lld of %lld"), 2, 3))
        XCTAssertEqual(try ReadingProgressRepository(context: context).fetchLocator(bookID: book.id), officeLocator)
    }

    func testFitsPageCapacityToFloatingWindowSize() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let suiteName = "gridnote-fit-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let viewModel = StealthReaderViewModel(context: ModelContext(container), defaults: defaults)

        viewModel.fitPage(to: CGSize(width: 420, height: 180))
        let compactCapacity = viewModel.charactersPerPage
        viewModel.fitPage(to: CGSize(width: 960, height: 520))

        XCTAssertGreaterThanOrEqual(compactCapacity, 80)
        XCTAssertGreaterThan(viewModel.charactersPerPage, compactCapacity)
    }

    func testSuperStealthPageFitCanConstrainToOneLine() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let suiteName = "gridnote-one-line-fit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let viewModel = StealthReaderViewModel(context: ModelContext(container), defaults: defaults)

        viewModel.fitPage(to: CGSize(width: 620, height: 42), maximumLines: 1)

        XCTAssertLessThan(viewModel.charactersPerPage, 80)
        XCTAssertGreaterThanOrEqual(viewModel.charactersPerPage, 8)
        XCTAssertLessThanOrEqual(
            Double(viewModel.charactersPerPage) * viewModel.fontSize * 1.08,
            620 - 32
        )
    }

    func testPixelPaginatorFitsMeasuredWidthAndUsesSemanticBoundary() {
        let text = NSString(string: "这是第一句话，用来验证像素分页。这里是第二句话，应当进入下一页继续显示。")
        let font = NSFont.systemFont(ofSize: 14)
        let boundaryWidth = NSAttributedString(
            string: "这是第一句话，用来验证像素分页。这里是第二句",
            attributes: [.font: font]
        ).size().width

        let layout = FloatingReaderPaginator.singleLineLayout(
            text: text,
            start: 0,
            maximumWidth: boundaryWidth,
            font: font
        )

        XCTAssertTrue(text.substring(with: layout.range).hasSuffix("。"))
        XCTAssertLessThanOrEqual(layout.measuredWidth, ceil(boundaryWidth))
    }

    func testPixelPaginatorContinuesWithoutOverlapOrMissingText() throws {
        let text = NSString(string: String(repeating: "甲乙丙丁戊己庚辛壬癸", count: 8))
        let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let first = FloatingReaderPaginator.singleLineLayout(text: text, start: 0, maximumWidth: 240, font: font)
        let nextOffset = try XCTUnwrap(first.nextOffset)
        let second = FloatingReaderPaginator.singleLineLayout(text: text, start: nextOffset, maximumWidth: 240, font: font)

        XCTAssertEqual(nextOffset, first.range.location + first.range.length)
        XCTAssertEqual(second.range.location, nextOffset)
        XCTAssertEqual(
            text.substring(with: first.range) + text.substring(with: second.range),
            text.substring(with: NSRange(location: 0, length: first.range.length + second.range.length))
        )
    }

    func testReloadPresentationSettingsUsesPersistedReaderAppearance() throws {
        let container = try GridnoteModelContainer.make(inMemory: true)
        let suiteName = "gridnote-presentation-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let viewModel = StealthReaderViewModel(context: ModelContext(container), defaults: defaults)
        ReaderPresentationSettings.save(color: .red, opacity: 0.42, to: defaults)
        viewModel.reloadPresentationSettings()

        XCTAssertEqual(viewModel.textOpacity, 0.42, accuracy: 0.0001)
    }

    func testSuperStealthDisplaySizeClampsToSafeBounds() {
        XCTAssertEqual(SuperStealthDisplaySize(width: 80, height: 40), SuperStealthDisplaySize(width: 260, height: 42))
        XCTAssertEqual(SuperStealthDisplaySize(width: 2000, height: 1000), SuperStealthDisplaySize(width: 1800, height: 600))
        XCTAssertEqual(
            SuperStealthDisplaySize(width: 700, maximumWidth: 500, height: 100),
            SuperStealthDisplaySize(width: 700, maximumWidth: 700, height: 100)
        )
    }

    func testVisibilityActionShowsAReaderThatWasHiddenByFocusLoss() {
        XCTAssertTrue(FloatingReaderVisibilityAction.shouldShow(isVisible: false))
        XCTAssertFalse(FloatingReaderVisibilityAction.shouldShow(isVisible: true))
    }

    func testFocusShieldSettingsClampAndPersist() throws {
        let suiteName = "gridnote-focus-shield-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(FloatingReaderFocusShieldSettings.delay(in: defaults), FloatingReaderFocusShieldSettings.defaultDelay)
        XCTAssertEqual(FloatingReaderFocusShieldSettings.usesFade(in: defaults), FloatingReaderFocusShieldSettings.defaultUsesFade)

        FloatingReaderFocusShieldSettings.save(delay: 99, usesFade: false, to: defaults)
        XCTAssertEqual(FloatingReaderFocusShieldSettings.delay(in: defaults), FloatingReaderFocusShieldSettings.delayRange.upperBound)
        XCTAssertFalse(FloatingReaderFocusShieldSettings.usesFade(in: defaults))
    }

    func testDensityPresetUpdatesReaderMetricsAndPersists() throws {
        let suiteName = "gridnote-density-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let container = try GridnoteModelContainer.make(inMemory: true)
        let viewModel = StealthReaderViewModel(context: ModelContext(container), defaults: defaults)

        viewModel.applyDensity(.spacious)

        XCTAssertEqual(viewModel.density, .spacious)
        XCTAssertEqual(viewModel.fontSize, FloatingReaderDensity.spacious.fontSize)
        XCTAssertEqual(viewModel.lineSpacing, FloatingReaderDensity.spacious.lineSpacing)
        let restored = StealthReaderViewModel(context: ModelContext(container), defaults: defaults)
        XCTAssertEqual(restored.density, .spacious)
    }

    func testTypographySettingsPersist() throws {
        let suiteName = "gridnote-typography-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let container = try GridnoteModelContainer.make(inMemory: true)
        let viewModel = StealthReaderViewModel(context: ModelContext(container), defaults: defaults)

        viewModel.fontFamily = .serif
        viewModel.fontWeight = .semibold
        viewModel.letterSpacing = 1.2

        let restored = StealthReaderViewModel(context: ModelContext(container), defaults: defaults)
        XCTAssertEqual(restored.fontFamily, .serif)
        XCTAssertEqual(restored.fontWeight, .semibold)
        XCTAssertEqual(restored.letterSpacing, 1.2, accuracy: 0.001)
    }

    func testShortcutRoutingUsesOfficeFormulaBarWhenFloatingReaderIsHidden() {
        XCTAssertEqual(
            StealthShortcutRouter.route(for: .previous, isFloatingReaderVisible: false, isGridnoteActive: true),
            .officeWorkspace
        )
        XCTAssertEqual(
            StealthShortcutRouter.route(for: .next, isFloatingReaderVisible: true, isGridnoteActive: true),
            .floatingReader
        )
        XCTAssertEqual(
            StealthShortcutRouter.route(for: .next, isFloatingReaderVisible: false, isGridnoteActive: false),
            .none
        )
        XCTAssertEqual(
            StealthShortcutRouter.route(for: .hide, isFloatingReaderVisible: false, isGridnoteActive: true),
            .toggleFloatingReader
        )
    }
}
