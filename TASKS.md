# Gridnote MVP Task List

This file defines the implementation sequence for Codex. Tasks should be executed in order unless this file explicitly says otherwise.

## Status

- Task 001: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 002: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 003: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 004: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 005: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 006: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 007: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 008: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 009: Complete and verified on Xcode 27.0 / macOS 27.0.
- Task 010: Complete and verified with unit, UI, and manual checks on Xcode 27.0 / macOS 27.0.
- Task 011: Complete and verified with unit and focused UI automation on Xcode 27.0 / macOS 27.0.
- Task 012: Complete and verified with 33 unit tests, 9 UI tests, fixture validation, performance smoke checks, and manual acceptance on Xcode 27.0 / macOS 27.0.

## Task 001: Repository Bootstrap

Goal:

- Create the initial macOS app project, test targets, directory structure, and placeholder workspaces.

Deliverables:

- `Gridnote.xcodeproj`
- `Gridnote`, `GridnoteTests`, and `GridnoteUITests` targets
- Root app entry point
- `AppShellView`
- Placeholder `OfficeWorkspaceView`
- Placeholder `ReaderWorkspaceView`
- Placeholder `LibraryView`
- Placeholder `SettingsView`

Out of scope:

- File import
- Parsing
- Persistence
- Disguise logic

Acceptance:

- The app builds.
- The app launches into `Office` mode.
- A minimal UI test asserts that office mode is visible on launch.
- The root folder structure matches `DIRECTORY_STRUCTURE.md` as closely as the initial project allows.

Required verification:

- `xcodebuild -list`
- Build the app scheme
- Run the test scheme

## Task 002: Domain Model And Persistence Baseline

Goal:

- Establish the canonical domain types and the initial `SwiftData` schema.

Deliverables:

- `BookFormat`
- `BookMetadata`
- `AliasProfile`
- `ReadingLocator`
- `GridnoteError`
- Initial `SwiftData` model entities and repositories

Out of scope:

- Real parsing
- Real import UI

Acceptance:

- Domain types compile cleanly.
- `ReadingLocator` round-trip tests pass.
- `SwiftData` records for books, aliases, and progress can be created and queried in tests.

Required verification:

- Build
- Domain and persistence tests

## Task 003: File Import And Bookmark Access

Goal:

- Add local file import, type detection, bookmark persistence, and missing-file recovery plumbing.

Deliverables:

- Import entry point from UI
- File type sniffing for `TXT` and `EPUB`
- Bookmark persistence service
- Source status tracking
- Re-link flow shell for missing files

Out of scope:

- Deep parsing correctness
- Office cell reader

Acceptance:

- Supported fixtures can be selected and recorded.
- Unsupported files fail cleanly.
- A book record is not persisted if import fails before a usable source is established.
- Simulated missing-file tests pass.

Required verification:

- Build
- Import unit tests
- Focused UI tests for import affordance

## Task 004: TXT Parser And Canonical Text Pipeline

Goal:

- Implement the first real parser and the normalized text path for `TXT`.

Deliverables:

- `TXTParser`
- Decoding fallback logic
- Paragraph chunking
- Parse-cache wiring for text sources

Out of scope:

- EPUB parsing
- Chapter heuristics beyond basic paragraph grouping

Acceptance:

- `UTF-8`, `UTF-16`, and `GB18030` fixtures import successfully.
- A corrupted text fixture fails cleanly.
- Parser tests cover decoding fallbacks.

Required verification:

- Build
- TXT parser tests

## Task 005: Standard Reader And Progress Restore

Goal:

- Implement the first usable reader workspace for normalized text content.

Deliverables:

- `ReaderViewModel`
- Standard text reader UI
- Reading progress persistence
- Reader reopen and restore flow
- Theme and typography controls wired to settings storage

Out of scope:

- Office disguise rendering
- EPUB parsing

Acceptance:

- A TXT fixture opens in reader mode.
- Progress persists across app restart.
- The user can toggle back to office mode with the defined shortcut.

Required verification:

- Build
- Reader tests
- UI test for launch, import, open, and restore path

## Task 006: EPUB Parser

Goal:

- Add non-DRM EPUB support on the canonical text model.

Deliverables:

- `EPUBParser`
- Spine parsing
- Basic metadata extraction
- TOC extraction
- Parse-cache support for EPUB

Out of scope:

- DRM support
- Advanced CSS fidelity
- External web resources

Acceptance:

- Basic EPUB fixtures import and read.
- TOC is available when present.
- Corrupted EPUB fixtures fail cleanly.

Required verification:

- Build
- EPUB parser tests
- Reader integration tests for EPUB

## Task 007: PDF Scope Removal

Goal:

- Remove PDF from the MVP after product scope was narrowed to text-first formats.

Deliverables:

- PDF rejected by import detection
- No PDF-specific source, test, fixture, or project references
- TXT/EPUB reader remains the only rendering path

Out of scope:

- PDF conversion
- OCR

Acceptance:

- PDF files fail as unsupported before a book record is created.
- The project builds without `PDFKit` or PDF reader code.
- TXT and EPUB regression tests pass.

Required verification:

- Build
- Import rejection test
- Full text-reader regression tests

## Task 008: Library UI

Goal:

- Build the compact local library experience around imported books.

Deliverables:

- List-based library UI
- Search by alias and actual title
- Detail pane or sheet
- Delete-from-library flow
- Missing-file and re-link affordance

Out of scope:

- Cover gallery
- Bulk library management

Acceptance:

- Imported books appear in the list with alias-first presentation.
- Selecting a row reveals actual metadata and source status.
- Search finds by alias and actual title.

Required verification:

- Build
- Library unit tests where applicable
- UI tests for list, search, and detail behavior

## Task 009: Office Workspace Shell

Goal:

- Implement the editable office-style spreadsheet shell.

Deliverables:

- Toolbar area
- Name box
- Formula bar
- Grid headers
- Editable grid
- Sheet tabs
- Status area
- Local office sheet persistence

Out of scope:

- Formula engine
- XLSX support
- Cell reader injection

Acceptance:

- The workspace reads visually as an office-style spreadsheet shell.
- Users can select and edit cells.
- Edited cell values persist after restart.

Required verification:

- Build
- Grid model tests
- Manual visual verification note

## Task 010: Cell Reader And Workspace Switching

Goal:

- Add the office disguise reading presentation and fast workspace switching.

Deliverables:

- `ExcerptInjector`
- Cell reader rendering in office mode
- App-focused workspace toggle shortcut
- Auto-switch to office on app deactivation when enabled
- Window title update path using alias metadata

Out of scope:

- System-wide hotkeys
- Additional disguise modes

Acceptance:

- Reader content appears inside the office sheet prose column.
- Switching between office and reader is fast and preserves progress.
- Actual titles never appear in the window title.
- With auto-switch enabled, deactivation resolves the app to office mode.

Required verification:

- Build
- Excerpt injection tests
- UI tests for switching
- Manual visual verification note

## Task 011: Settings And Alias Management

Goal:

- Finish the user-facing controls needed to make the MVP usable.

Deliverables:

- Alias editing UI
- Workbook title editing UI
- Sheet name editing UI
- Theme, font size, and line height settings
- Auto-switch setting

Out of scope:

- Password locking
- Touch ID
- Cloud sync

Acceptance:

- Alias changes persist.
- Window title updates after alias changes.
- Reading settings affect the standard reader.
- Office auto-switch setting persists.

Required verification:

- Build
- Settings and alias tests
- Focused UI tests for settings flows

## Task 012: Hardening, Fixtures, And Release Readiness

Goal:

- Close the MVP with missing tests, fixtures, polish, and release notes.

Deliverables:

- Full fixture set from `TEST_PLAN.md`
- Remaining unit and UI coverage needed for release gates
- Error copy review
- Performance smoke measurements
- Final README updates

Out of scope:

- Post-MVP feature expansion

Acceptance:

- Full build and test pass.
- Manual acceptance checklist is complete.
- Performance smoke results are recorded.
- Remaining known limitations are explicitly documented.

Required verification:

- Build
- Full test suite
- Manual acceptance run

## Parallelization Rule

Do not parallelize implementation before `Task 005` is complete.

After `Task 005`, limited parallel work is acceptable between:

- `Task 006` and `Task 007`
- `Task 008` and `Task 009`

`Task 010` and later tasks should merge only after their prerequisites are complete.
