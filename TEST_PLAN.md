# Gridnote Test Plan

Version: `1.0`

## 1. Test Goals

This plan defines the minimum evidence required to accept the Gridnote MVP.

The goals are:

- Prove supported formats import and reopen correctly.
- Prove the app launches into `Office` mode by default.
- Prove reading progress persists across app restarts.
- Prove disguise metadata controls titles and library presentation.
- Prove the app works fully offline.

## 2. Test Layers

## 2.1 Unit Tests

Required unit coverage areas:

- `TXT` decoding and fallback behavior
- `EPUB` package parsing
- `ReadingLocator` encode and decode round trips
- `SwiftData` repository behavior for book records and progress
- `ExcerptInjector` behavior for office formula-bar projection
- Bidirectional reading-progress synchronization
- Settings persistence

## 2.2 UI Tests

Required UI coverage areas:

- First launch shows office workspace
- Empty state import affordance is visible
- Importing a supported fixture creates a library item
- Opening a library item selects it for office and floating reading
- Showing and hiding the floating reader preserves progress
- Alias title appears where expected
- Missing file state surfaces a re-link option

## 2.3 Manual Acceptance Tests

Manual testing remains required for:

- Visual credibility of the office shell
- Reading comfort in both floating and office formula-bar modes
- Window title behavior while showing and hiding the floating reader
- Focus loss behavior
- Performance smoke checks

## 3. Test Environments

Minimum environments:

- Apple Silicon Mac
- Current Xcode toolchain available to the implementation environment
- Light mode and dark mode

Network should be disabled or ignored for at least one acceptance pass to verify offline behavior.

UI automation is not part of the default CI job because macOS test launches can request local permissions and block unattended runners. Run UI tests manually on a dedicated development Mac after granting the required test-runner permissions.

## 4. Required Test Fixtures

Store fixtures in-repo. Do not fetch them at runtime.

Required fixture categories:

- `TXT/utf8-sample.txt`
- `TXT/utf16-sample.txt`
- `TXT/gb18030-sample.txt`
- `TXT/large-20mb.txt`
- `EPUB/basic-with-toc.epub`
- `EPUB/basic-with-images.epub`
- `EPUB/corrupted.epub`

Fixtures should be legally safe, small when possible, and not sourced from copyrighted commercial books.

## 5. Release Gates

The MVP cannot be accepted unless all of the following are true:

- Build succeeds for the `Gridnote` scheme.
- Unit tests pass.
- UI tests pass.
- Manual acceptance checklist is complete.
- No network dependency exists for core import, reading, and switching flows.

## 6. Automated Test Matrix

## 6.1 Import And Parsing

- Import `UTF-8` TXT succeeds.
- Import `UTF-16` TXT succeeds.
- Import `GB18030` TXT succeeds when Unicode decode fails.
- Import corrupt TXT fails cleanly.
- Import non-DRM EPUB succeeds.
- Import corrupt EPUB fails cleanly.
- Import PDF is rejected without creating a book record.

## 6.2 Persistence

- Imported book record survives app restart.
- Alias metadata survives app restart.
- Reading locator survives app restart for `TXT` and `EPUB`.
- Office sheet state survives app restart.

## 6.3 Workspace Behavior

- Launch defaults to office mode.
- `Option + Command + X` toggles focused app mode.
- `Escape` exits reader mode to office mode.
- With auto-switch enabled, app deactivation resolves to office mode.
- Window title uses alias metadata, not actual title.

## 7. Manual Acceptance Checklist

## 7.1 Core Product

- Import one `TXT` and one `EPUB` file.
- Confirm each item appears in the library.
- Confirm the library favors alias presentation over actual title presentation.
- Open each format and confirm reading works.
- Quit and relaunch the app, then confirm progress restores.

## 7.2 Office Shell

- Launch the app and confirm office mode is the default visible state.
- Confirm the office shell includes toolbar, formula bar, headers, grid, tabs, and status area.
- Edit several cells and confirm values persist after restart.
- Bind an imported book to the office shell and confirm reading text appears in the designated prose column.
- Confirm the screen still reads as an office-style workspace from a glance.

## 7.3 Switching

- With a book open in reader mode, trigger the toggle shortcut and confirm return to office mode is immediate.
- Confirm no reader cover, library, or actual title flashes during the switch.
- With auto-switch enabled, deactivate the app and confirm it returns to office mode before next activation.

## 7.4 Error Recovery

- Move a referenced source file in Finder.
- Reopen the associated library item.
- Confirm Gridnote reports the source as missing and offers re-link.
- Re-link the file and confirm reading resumes.

## 8. Performance Smoke Checks

These are not strict benchmarks but must be measured and reported:

- Time to cold launch to office workspace
- Time to import `large-20mb.txt`
- Time to toggle from reader to office
- Time to reopen last-read book

Soft targets:

- Launch under `2 seconds`
- Toggle under `150 ms`
- Large TXT import under `5 seconds` in release validation

## 9. Test Execution Commands

Once the project exists, default verification commands are:

```bash
xcodebuild -project Gridnote.xcodeproj -scheme Gridnote -destination 'platform=macOS' build
xcodebuild -project Gridnote.xcodeproj -scheme Gridnote -destination 'platform=macOS' -parallel-testing-enabled NO -skip-testing:GridnoteUITests test
```

Additional focused commands may be used for parser-only or UI-only changes, but the full test run remains the release gate.
