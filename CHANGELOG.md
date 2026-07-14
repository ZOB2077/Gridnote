# Changelog

All notable changes are documented in this file. Gridnote follows [Semantic Versioning](https://semver.org/) for public releases where practical.

## [0.1.1] - 2026-07-14

### Security

- Rebuilt all office disguise tables from a data-minimized catalog containing only deduplicated public product names.
- Replaced every order ID, device ID, specification, date, status, amount, warehouse, risk value, and relationship with deterministic synthetic data.
- Added ignored business-data extensions, a pre-commit repository hygiene check, and the same enforcement in CI.

### Changed

- Replaced aggregate business-report layouts with synthetic order detail, order progress, warehouse fulfillment, and device ledger templates.
- Added automatic migration from prior built-in office templates and removed reference-workbook naming from default sheet titles.
- Removed floating-window edge snapping so the reader remains exactly where it is placed.
- Prevented Super Stealth one-line pages from ending in an ellipsis by using CJK-safe page sizing and flattening paragraph breaks for display.
- Cached TXT chapter-heading expressions, substantially reducing large-file parsing time.

## [0.1.0] - 2026-07-13

### Added

- Local TXT and non-DRM EPUB import, parsing, search, bookmarks, and persistent reading locations.
- Original office-style phone-rental data workspace with formula-bar reading presentation.
- Floating reader, Super Stealth mode, configurable appearance, progress indicator, and menu-bar controls.
- Default shortcut profile: `F7` previous, `F8` next, and `F9` show or hide the floating reader.
- Per-book aliases, local workbook titles, dense synthetic office templates, and privacy shielding when the app loses focus.
- Source-available non-commercial license and commercial-licensing path.

### Changed

- Office formula-bar navigation and the floating reader now synchronize reading progress in both directions.
- The office workspace uses an original presentation and does not expose book text inside spreadsheet cells.

### Known Limitations

- PDF, cloud sync, network features, accounts, DRM handling, XLSX compatibility, notarization, and global shortcuts are not included.

[0.1.0]: https://github.com/ZOB2077/Gridnote/releases/tag/v0.1.0
[0.1.1]: https://github.com/ZOB2077/Gridnote/releases/tag/v0.1.1
