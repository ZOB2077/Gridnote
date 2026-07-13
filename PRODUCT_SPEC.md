# Gridnote Product Spec

Version: `1.0`
Status: `Approved for MVP implementation`
Audience: `Codex, future maintainers, and the product owner`

## 1. Product Summary

`Gridnote` is a local-first macOS reading app for personal use. Its defining feature is an office-style spreadsheet workspace that can present reading content in a visually credible work-like layout, while still offering a normal reading mode when the user wants a cleaner view.

The app does not attempt to defeat system logging, enterprise monitoring, screen recording, or device management. The product goal is visual disguise for nearby observers on a personal Mac, not technical evasion.

## 2. Product Goals

- Open and read local `TXT` and `EPUB` files.
- Launch into an office-style workspace by default.
- Allow the user to switch between `Office` and `Reader` workspaces instantly while the app is focused.
- Preserve reading progress locally and reliably.
- Allow every imported book to have separate disguise metadata such as alias title, workbook title, and sheet name.
- Work fully offline after installation.

## 3. Non-Goals For MVP

- Networking, accounts, analytics, or cloud sync.
- DRM support or DRM removal.
- Full spreadsheet compatibility, `.xlsx` fidelity, formulas, macros, or Office import/export.
- System-wide global hotkeys that work when Gridnote is not focused.
- OCR, annotations, highlights, export, or quote syncing.
- Full-text search across the whole book.
- Multi-window reading, split reading, or tabbed multi-book reading.
- iPhone, iPad, or Windows support.

## 4. Product Assumptions

- The primary user is a single person on a personal Mac.
- The user opens files they already have permission to access.
- The app may target the newest macOS SDK available locally, but product behavior must remain aligned with a modern macOS desktop experience.
- The MVP should be practical to implement without external services or external parser dependencies.

## 5. MVP Scope

The MVP must include the following:

- Import local `TXT` and `EPUB` files.
- Persist file access using security-scoped bookmarks when needed.
- Maintain a local library list.
- Provide an office-style spreadsheet workspace.
- Provide a disguised formula-bar reading presentation above the office grid.
- Provide a movable, resizable floating reader controlled from the toolbar or menu bar.
- Persist reading progress per book.
- Persist alias metadata per book.
- Persist office workspace state and last visible mode.
- Automatically return to office mode when the app loses focus, if the setting is enabled.
- Allow basic editing of office grid cells as plain text or numbers.

## 6. Core User Experience

## 6.1 First Launch

- The app opens into `Office` mode.
- If the library is empty, the office workspace displays template sample data and an obvious local import action.
- No cover wall or book-themed UI is shown by default.

## 6.2 Import Flow

- The user imports a book by file picker or drag and drop.
- Supported formats are accepted: `TXT`, `EPUB`.
- Unsupported or protected files are rejected with a clear local-only error message.
- After import, the app extracts detectable metadata when possible.
- The app asks the user for disguise metadata or assigns defaults:
  - Alias title
  - Workbook title
  - Sheet name
  - Template family
- The imported book appears in the library list immediately.

## 6.3 Library

The library is a compact list, not a cover gallery.

Each row shows:

- Alias title
- Format
- Progress
- Last opened
- Source status

Selecting a row reveals a details panel or sheet with:

- Actual detected title
- Author if known
- Source file path
- Alias settings
- File access status

The library must support:

- Import
- Delete from library
- Re-link missing source file
- Open selected book
- Search by alias title and actual title

## 6.4 Reading Surfaces

Gridnote focuses on two reading surfaces: the office formula bar and the floating reader. A separate full-screen or standard reader workspace is not part of the current product flow.

MVP requirements:

- Configurable text color, opacity, font size, and line spacing.
- Search, bookmarks, chapter navigation, and reliable progress restoration.
- Page-based navigation without a vertical scrollbar in the floating reader.
- Bidirectional progress synchronization between both reading surfaces.

The MVP does not include:

- A dedicated immersive reading workspace.
- Notes, highlights, or page-curl effects.
- Web content or online reading sources.

## 6.5 Office Workspace

The office workspace is the default surface and the disguise layer.

It must visually include:

- A toolbar area
- A name box
- A formula bar
- Column headers
- Row headers
- A scrollable grid
- Sheet tabs
- A status area

It must behaviorally include:

- Cell selection
- Keyboard navigation
- Plain text and number editing
- Persistent local sheet content
- Template-based starter data

It must not include:

- Real spreadsheet formulas
- `.xlsx` import/export
- Charts, pivot tables, or macros

## 6.6 Formula-Bar Reader

The disguised reading presentation is placed in the formula bar above the office grid.

Behavior:

- The office sheet remains filled with deterministic synthetic demo data and does not contain book text or real business records.
- The active excerpt appears in the formula bar as if it were selected-cell content.
- `F7` and `F8` navigate excerpts while Gridnote is focused and the floating reader is hidden.
- The excerpt can automatically change to a neutral business note after a configurable delay or when the pointer leaves the area.
- Search and bookmark actions operate on the same shared reading location used by the floating reader.

Acceptance intent:

- Up close, the user can read prose.
- At a glance, the screen still resembles a populated spreadsheet workspace.

## 6.7 Workspace Switching

MVP visibility rules:

- `F9` shows or hides the floating reader.
- When the app resigns active and focus shielding is enabled, the floating reader hides and the formula bar conceals its excerpt.
- `F9` can restore a reader hidden by focus shielding.
- Hiding and restoring must preserve reading location.
- Visibility changes must not flash a cover image, library view, or actual book title in the window title.

System-wide global shortcuts are out of scope for MVP.

## 6.8 Floating Reader

The optional `Floating Reader` is a compact always-on-top panel for short reading sessions.

- It uses the currently selected or most recently opened TXT/EPUB book.
- It paginates normalized text by a configurable character count.
- It persists progress through the same `ReadingProgressRecord` used by the office formula bar.
- It supports previous/next controls, search, bookmarks, chapter navigation, typography, text opacity, panel opacity, and reading progress.
- It can be shown or hidden from the main toolbar or Gridnote menu bar item.
- It joins all Spaces and may appear beside full-screen apps.
- Super Stealth mode removes chrome and controls, can display a single line, and exposes controls through the menu bar.
- It uses Carbon hot-key registration for the configured shortcuts and does not require Accessibility permission.

## 6.8 Titles And Aliases

Each book has two identities:

- Actual metadata
- Disguise metadata

MVP disguise metadata fields:

- Alias title
- Workbook title
- Sheet name
- Template family

The window title must always use workbook title or alias title, never the actual book title.

## 6.9 Settings

MVP settings groups:

- Reading
  - Theme
  - Font size
  - Line height
- Office
  - Default template
  - Auto-switch to office on app deactivation
- Library and Privacy
  - Reveal source path
  - Remove book from library
  - Re-link missing file

## 7. Supported Formats

## 7.1 TXT

Required behavior:

- Detect UTF-8, UTF-16, and common BOM variants.
- Fall back to `GB18030` when Unicode decoding fails.
- Handle large files incrementally.
- Preserve paragraph boundaries where possible.

## 7.2 EPUB

Required behavior:

- Support non-DRM EPUB packages.
- Parse package metadata.
- Parse spine order.
- Parse text content and basic inline images.
- Parse table of contents when present.

## 7.3 Unsupported Formats

PDF and other formats outside TXT/EPUB are rejected during import. The MVP contains no PDF rendering, extraction, OCR, or progress support.

## 8. State Persistence

The app stores all state locally.

Required persisted state:

- Imported book records
- Security-scoped bookmark data when applicable
- Alias metadata
- Reading progress per book
- Office sheet contents
- Last selected book
- Last visible workspace mode
- User settings

## 9. Error Handling

Required user-visible cases:

- Unsupported file type
- DRM or unreadable EPUB package
- Corrupted TXT encoding
- Missing source file
- Bookmark access failure
- Empty library

Required behavior:

- Errors are local and non-technical.
- The app offers re-link when a source file moved or disappeared.
- A failed import does not create a half-valid library item.

## 10. Performance And UX Targets

Soft targets for MVP on a recent Apple Silicon Mac:

- Cold launch to visible office workspace within `2 seconds`.
- Workspace toggle within `150 ms`.
- Open a `20 MB` TXT file within `5 seconds` in release validation.
- Reopen last book to the correct location with no more than one paragraph of drift for text formats.

## 11. Privacy And Platform Rules

- No network dependency for core functionality.
- No analytics, telemetry, or advertising SDKs.
- No private macOS APIs.
- No Microsoft trademarks, icons, or proprietary UI assets.
- All user-visible strings must be localizable.

## 12. Product Acceptance Criteria

The MVP is acceptable only if all of the following are true:

- A user can import and read `TXT` and `EPUB` files offline.
- The app launches into `Office` mode by default.
- The office workspace looks like an original office-style spreadsheet shell, not a broken or empty placeholder.
- The formula bar displays readable prose above a populated office-like sheet layout.
- The user can show or hide the floating reader instantly and can restore it after focus shielding.
- Office formula-bar navigation and floating-reader navigation remain synchronized.
- The app restores the last reading position for each supported format.
- Actual book titles are not used in the window title.
- Missing files surface a recoverable re-link path.
- The MVP builds and passes its required automated tests.
