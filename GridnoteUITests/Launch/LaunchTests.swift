import XCTest

@MainActor
final class LaunchTests: XCTestCase {
    func testLaunchShowsOfficeWorkspace() {
        let app = makeApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["office-workspace"].waitForExistence(timeout: 10))
    }

    func testOfficeWorkspaceShowsImportAffordance() {
        let app = makeApplication()
        app.launch()

        XCTAssertTrue(app.buttons["import-book"].waitForExistence(timeout: 10))
    }

    func testFloatingReaderShowsSelectedBookText() throws {
        let fixtureURL = try makeTemporaryTXT()
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-floating-ui-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: fixtureURL) }
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let app = makeApplication()
        app.launchEnvironment["GRIDNOTE_TEST_IMPORT_PATH"] = fixtureURL.path
        app.launchEnvironment["GRIDNOTE_TEST_STORE_PATH"] = storeURL.path
        app.launch()
        app.activate()

        let showFloatingReader = app.buttons["show-floating-reader"]
        XCTAssertTrue(showFloatingReader.waitForExistence(timeout: 10))
        showFloatingReader.click()
        XCTAssertTrue(
            app.descendants(matching: .any)["stealth-reader-overlay"]
                .waitForExistence(timeout: 10)
        )
        XCTAssertTrue(app.staticTexts["First paragraph\n\nSecond paragraph"].exists)
    }

    func testFocusedWorkspaceSwitchAndEscapeNeverExposeActualTitleInWindow() throws {
        let fixtureURL = try makeTemporaryTXT()
        let actualTitle = fixtureURL.deletingPathExtension().lastPathComponent
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-switch-ui-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: fixtureURL) }
        defer { try? FileManager.default.removeItem(at: storeURL) }
        let app = makeApplication()
        app.launchEnvironment["GRIDNOTE_TEST_IMPORT_PATH"] = fixtureURL.path
        app.launchEnvironment["GRIDNOTE_TEST_STORE_PATH"] = storeURL.path
        app.launch(); app.activate()
        XCTAssertTrue(app.buttons["workspace-toggle"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.windows.firstMatch.title.contains(actualTitle))
        app.typeKey("x", modifierFlags: [.command, .option])
        let returnToOffice = app.buttons["return-to-office"]
        if !returnToOffice.waitForExistence(timeout: 2) {
            app.activate()
            app.typeKey("x", modifierFlags: [.command, .option])
        }
        XCTAssertTrue(returnToOffice.waitForExistence(timeout: 10))
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["office-workspace"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.windows.firstMatch.title.contains(actualTitle))
    }

    func testSettingsAliasFlowUpdatesDisguiseTitle() throws {
        let fixtureURL = try makeTemporaryTXT()
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-settings-ui-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: fixtureURL) }
        defer { try? FileManager.default.removeItem(at: storeURL) }
        let app = makeApplication()
        app.launchEnvironment["GRIDNOTE_TEST_IMPORT_PATH"] = fixtureURL.path
        app.launchEnvironment["GRIDNOTE_TEST_STORE_PATH"] = storeURL.path
        app.launch(); app.activate()
        XCTAssertTrue(app.buttons["show-settings"].waitForExistence(timeout: 10)); app.buttons["show-settings"].click()
        let officeTab = app.tabs["Office"]
        XCTAssertTrue(officeTab.waitForExistence(timeout: 10)); officeTab.click()
        let workbook = app.textFields["workbook-title"]
        XCTAssertTrue(workbook.waitForExistence(timeout: 10))
        workbook.click(); workbook.typeKey("a", modifierFlags: .command); workbook.typeText("Q3 Operations.xlsx")
        app.buttons["save-alias"].click()
        let confirmation = app.buttons["action-button-1"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10)); confirmation.click()
        XCTAssertTrue(app.windows.firstMatch.title.contains("Q3 Operations.xlsx"))
    }

    func testLibraryListsSearchesAndShowsBookDetails() throws {
        let fixtureURL = try makeTemporaryTXT()
        let expectedTitle = fixtureURL.deletingPathExtension().lastPathComponent
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-library-ui-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: fixtureURL) }
        defer { try? FileManager.default.removeItem(at: storeURL) }
        let app = makeApplication()
        app.launchEnvironment["GRIDNOTE_TEST_IMPORT_PATH"] = fixtureURL.path
        app.launchEnvironment["GRIDNOTE_TEST_STORE_PATH"] = storeURL.path
        app.launch(); app.activate()
        XCTAssertTrue(app.buttons["show-library"].waitForExistence(timeout: 10)); app.buttons["show-library"].click()
        XCTAssertTrue(app.staticTexts["library-row-title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Actual title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[expectedTitle].exists)
        let search = app.textFields["library-search"]
        XCTAssertTrue(search.exists); search.click(); search.typeText("no-match-query")
        XCTAssertFalse(app.staticTexts["library-row-title"].exists)
    }

    func testLibraryReadActionOpensSelectedBook() throws {
        let fixtureURL = try makeTemporaryTXT()
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-library-read-ui-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: fixtureURL) }
        defer { try? FileManager.default.removeItem(at: storeURL) }
        let app = makeApplication()
        app.launchEnvironment["GRIDNOTE_TEST_IMPORT_PATH"] = fixtureURL.path
        app.launchEnvironment["GRIDNOTE_TEST_STORE_PATH"] = storeURL.path
        app.launch(); app.activate()
        XCTAssertTrue(app.buttons["show-library"].waitForExistence(timeout: 10)); app.buttons["show-library"].click()
        XCTAssertTrue(app.buttons["library-read"].waitForExistence(timeout: 10)); app.buttons["library-read"].click()
        XCTAssertTrue(app.staticTexts["First paragraph"].waitForExistence(timeout: 10))
    }

    func testMissingLibrarySourceOffersRelink() throws {
        let fixtureURL = try makeTemporaryTXT()
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("gridnote-missing-ui-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: fixtureURL) }
        defer { try? FileManager.default.removeItem(at: storeURL) }
        let app = makeApplication()
        app.launchEnvironment["GRIDNOTE_TEST_IMPORT_PATH"] = fixtureURL.path
        app.launchEnvironment["GRIDNOTE_TEST_STORE_PATH"] = storeURL.path
        app.launchEnvironment["GRIDNOTE_TEST_SOURCE_MISSING"] = "1"
        app.launch(); app.activate()
        XCTAssertTrue(app.buttons["show-library"].waitForExistence(timeout: 10)); app.buttons["show-library"].click()
        XCTAssertTrue(app.staticTexts["missing"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["library-relink"].exists)
    }

    private func makeTemporaryTXT() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridnote-ui-reader-\(UUID().uuidString)")
            .appendingPathExtension("txt")
        try Data("First paragraph\n\nSecond paragraph".utf8).write(to: url)
        return url
    }

    private func makeApplication() -> XCUIApplication {
        continueAfterFailure = false
        let application = XCUIApplication()
        addTeardownBlock { @MainActor in
            if application.state != .notRunning {
                application.terminate()
            }
        }
        return application
    }

}
