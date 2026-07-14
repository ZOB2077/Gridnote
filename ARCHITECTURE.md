# Gridnote Architecture

Version: `1.0`
Status: `Accepted baseline for MVP`

## 1. Architecture Goals

The codebase must optimize for:

- Clear separation between parsing, persistence, UI, and disguise logic.
- Fast workspace switching with stable state.
- Local-first behavior with no network layer.
- Incremental delivery across small Codex tasks.
- Minimal external complexity in MVP.

## 2. High-Level Shape

Gridnote uses a single-process macOS app with a primary window, two resident workspaces, a menu bar scene, and one optional AppKit floating panel:

- `OfficeWorkspace`
- `ReaderWorkspace`
- `StealthReader`

The app keeps both workspaces in memory once initialized and switches visible state instead of reconstructing the full tree on every toggle.

## 3. Recommended Repository Modules

```text
Gridnote
├── App
│   ├── GridnoteApp.swift
│   ├── AppShellView.swift
│   ├── AppState.swift
│   ├── WorkspaceCoordinator.swift
│   └── WindowCoordinator.swift
├── Domain
│   ├── BookDocument.swift
│   ├── BookMetadata.swift
│   ├── AliasProfile.swift
│   ├── ReadingLocator.swift
│   ├── OfficeSheet.swift
│   └── GridnoteError.swift
├── Persistence
│   ├── Model
│   ├── BookmarkStore.swift
│   ├── Repository
│   └── Cache
├── Parsers
│   ├── ParserProtocol.swift
│   ├── TXT
│   └── EPUB
├── Library
│   ├── LibraryView.swift
│   ├── LibraryViewModel.swift
│   └── ImportService.swift
├── Reader
│   ├── ReaderView.swift
│   ├── ReaderViewModel.swift
│   └── TextReader
├── StealthReader
│   ├── StealthReaderViewModel.swift
│   ├── StealthOverlayView.swift
│   ├── StealthOverlayController.swift
│   └── StealthMenuBarView.swift
├── Office
│   ├── OfficeWorkspaceView.swift
│   ├── OfficeViewModel.swift
│   ├── GridModel.swift
│   └── ExcerptInjector.swift
├── Settings
│   ├── SettingsView.swift
│   └── SettingsStore.swift
└── Shared
    ├── UI
    ├── Utilities
    └── Localization
```

## 4. Core Architectural Decisions

- Use `SwiftUI` for the main app structure and most views.
- Use `AppKit` only for window title updates, focus notifications, and other macOS-specific behavior that is awkward or incomplete in pure SwiftUI.
- Use `SwiftData` for persisted app state in MVP.
- Use no third-party parsing libraries in MVP.
- Keep floating-reader pagination in a separate view model while sharing canonical parsers and reading-progress repositories.
- Use an `NSPanel` only for the nonactivating always-on-top floating surface.

## 5. Domain Model

## 5.1 Canonical Book Model

`TXT` and `EPUB` should normalize into a shared in-memory book model:

```swift
struct BookDocument {
    let id: UUID
    let format: BookFormat
    let metadata: BookMetadata
    let chapters: [BookChapter]
    let toc: [TOCEntry]
}
```

Supporting types:

- `BookFormat`: `txt`, `epub`
- `BookMetadata`: title, author, language, source filename
- `BookChapter`: chapter id, title, ordered text blocks
- `TextBlock`: paragraph-level or paragraph-chunk text unit
- `TOCEntry`: title, chapter reference, depth

PDF is rejected as unsupported and has no adapter or rendering path.

## 5.2 Alias And Disguise Model

Each book record owns an alias profile:

```swift
struct AliasProfile {
    var aliasTitle: String
    var workbookTitle: String
    var sheetName: String
    var templateFamily: OfficeTemplateFamily
}
```

## 5.3 Reading Locator

Use a format-specific enum to avoid false abstraction:

```swift
enum ReadingLocator: Codable, Equatable {
    case text(chapterID: String, blockIndex: Int, intraBlockOffset: Int)
    case epub(spineItemID: String, blockIndex: Int, intraBlockOffset: Int)
}
```

## 6. Persistence Model

`SwiftData` should hold persistent records, not view state objects.

Recommended persisted entities:

- `BookRecord`
- `ReadingProgressRecord`
- `AliasProfileRecord`
- `OfficeSheetRecord`
- `AppSettingsRecord`
- `WorkspaceSessionRecord`

## 6.1 BookRecord Responsibilities

- Stable local id
- Source path metadata
- Bookmark data
- File fingerprint
- Detected title and author
- Source format
- Parse status
- Last opened date

## 6.2 OfficeSheetRecord Responsibilities

- Grid cell values
- Selected cell
- Scroll position
- Active sheet name
- Template family
- Last injected excerpt range

## 6.3 Cached Parse Artifacts

To reduce reload cost:

- Cache normalized `TXT` and `EPUB` parse output in app support storage.
- Version the cache format with a parser version number.
- Invalidate cache when source fingerprint changes or parser version changes.
- Do not cache a second full copy of the original imported file in MVP.

## 7. File Access Strategy

MVP uses a reference-in-place strategy.

Rules:

- Do not copy imported books into an app-managed library in MVP.
- Persist bookmark data for files chosen through open panels or drag-and-drop flows that require future access.
- Resolve the bookmark every time the source is reopened.
- If resolution fails, mark the source as missing and surface a re-link flow.

This keeps the MVP small and avoids duplicate storage management.

## 8. Parser Strategy

## 8.1 TXT Parser

Responsibilities:

- Detect BOM where present.
- Attempt Unicode decode first.
- Fall back to `GB18030`.
- Normalize line endings.
- Chunk text into paragraphs.
- Generate chapter heuristics later only if explicitly added by task.

MVP does not require advanced chapter recognition for `TXT`.

## 8.2 EPUB Parser

Responsibilities:

- Unzip container.
- Read `META-INF/container.xml`.
- Read package document.
- Resolve manifest and spine.
- Read XHTML spine items.
- Strip unsupported scripting and external references.
- Extract paragraphs and basic image references.
- Build a TOC from nav document or NCX when present.

## 8.3 Unsupported Inputs

The import boundary rejects PDF and every format other than TXT/EPUB before a book record is created.

## 9. UI Architecture

## 9.1 Root Composition

`AppShellView` owns the visible workspace state:

```swift
enum WorkspaceMode {
    case office
    case reader
}
```

Recommended shape:

- Single main window
- Shared `AppState` injected into both workspaces
- `ZStack` or equivalent root that swaps visible focus between office and reader layers
- Library and settings presented as sheets or split panels, not separate windows, in MVP

## 9.2 State Machine

```text
Launch -> Office

Office
  ImportBook -> Office
  OpenBook -> Reader
  ToggleWorkspace -> Reader
  OpenLibrary -> Office + LibrarySheet

Reader
  ToggleWorkspace -> Office
  Escape -> Office
  AppResignActive -> Office (if setting enabled)
  CloseBook -> Office
```

Persistence events:

- Save reading locator on chapter change, scroll settle, workspace toggle, app deactivation, and app termination.
- Save office grid snapshot on cell commit, sheet change, workspace toggle, and app termination.

## 9.3 Window Behavior

`WindowCoordinator` is responsible for:

- Updating the window title from alias metadata
- Restoring window size and position
- Observing app activation and deactivation

The window title must never be populated from actual book metadata.

## 10. Office Disguise Rendering

The office workspace should be a genuine app surface, not a static screenshot.

Required pieces:

- `GridModel` for row and column addressing
- Editable cell model for local plain-text content
- `ExcerptInjector` that projects current reading blocks into a designated visible text column

Recommended strategy:

- Keep template and user-entered data in separate fields from injected reading text.
- At render time, merge visible office cells with the active injected excerpt.
- This avoids corrupting the user's office-like notes when reading chunks advance.

## 11. Reader Rendering

Text-based reader:

- Render normalized text blocks in SwiftUI.
- Use a view model that tracks the visible chapter and block range.
- Persist a locator after the view becomes stable, not on every pixel of scroll.

## 12. Error Model

Create a unified app error surface:

```swift
enum GridnoteError: LocalizedError {
    case unsupportedFormat
    case bookmarkResolutionFailed
    case sourceFileMissing
    case parseFailed
    case pdfLoadFailed
    case epubProtected
}
```

Error handling rules:

- Parser failures never leave partially valid persisted progress.
- A failed refresh does not silently erase prior good cached content.
- User-facing messages stay plain and local.

## 13. Testing Strategy

Unit test layers:

- Parser unit tests
- Locator serialization tests
- Repository tests
- Excerpt injection tests
- Settings persistence tests

UI test layers:

- Launch defaults to office workspace
- Import flow
- Reader to office toggle
- Alias title appears in window title and library row

Performance smoke tests:

- Large TXT import
- Workspace switch latency
- Reader restore latency

## 14. Out-Of-Scope Architectural Work

Do not add these in MVP:

- Networking layer
- Sync engine
- Dependency injection framework
- Plugin system
- Full document editor
- Global system hotkey manager
- Multi-window scene coordination

## 15. Implementation Order Constraint

Parallel development is discouraged until these are stable:

- Canonical domain model
- Persistence schema
- TXT parser contract
- Reader progress contract

After those stabilize, `EPUB` and `Office` work can proceed with lower merge risk.
