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
        XCTAssertTrue(viewModel.canGoNext)

        viewModel.next()
        XCTAssertEqual(viewModel.pageRevision, 1)
        XCTAssertEqual(viewModel.pageDirection, .forward)
        XCTAssertEqual(viewModel.progressText, String(format: String(localized: "Record %lld of %lld"), 2, 3))
        let locator = try XCTUnwrap(ReadingProgressRepository(context: context).fetchLocator(bookID: book.id))
        guard case let .text(_, blockIndex, intraBlockOffset) = locator else {
            return XCTFail("Expected text progress")
        }
        XCTAssertEqual(blockIndex, 0)
        XCTAssertEqual(intraBlockOffset, 80)
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

    func testFloatingPanelSnapperSnapsOnlyNearHorizontalScreenEdges() {
        let visibleFrame = CGRect(x: 0, y: 24, width: 1440, height: 876)
        let panelSize = CGSize(width: 420, height: 180)

        XCTAssertEqual(
            FloatingPanelSnapper.snappedOrigin(
                panelFrame: CGRect(origin: CGPoint(x: 20, y: 240), size: panelSize),
                visibleFrame: visibleFrame
            ),
            CGPoint(x: 0, y: 240)
        )
        XCTAssertEqual(
            FloatingPanelSnapper.snappedOrigin(
                panelFrame: CGRect(origin: CGPoint(x: 996, y: 240), size: panelSize),
                visibleFrame: visibleFrame
            ),
            CGPoint(x: 1020, y: 240)
        )
        XCTAssertEqual(
            FloatingPanelSnapper.snappedOrigin(
                panelFrame: CGRect(origin: CGPoint(x: 500, y: 240), size: panelSize),
                visibleFrame: visibleFrame
            ),
            CGPoint(x: 500, y: 240)
        )
    }

    func testSuperStealthDisplaySizeClampsToSafeBounds() {
        XCTAssertEqual(SuperStealthDisplaySize(width: 80, height: 40), SuperStealthDisplaySize(width: 260, height: 42))
        XCTAssertEqual(SuperStealthDisplaySize(width: 2000, height: 1000), SuperStealthDisplaySize(width: 1200, height: 600))
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
