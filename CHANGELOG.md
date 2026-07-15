# Changelog

All notable changes are documented in this file. Gridnote follows [Semantic Versioning](https://semver.org/) for public releases where practical.

## [0.1.6] - 2026-07-15

### Added

- Added a live Super Stealth size and typography preview to the main settings window.
- Added continuous intra-paragraph pagination and exact progress persistence to the office formula-bar reader.

### Changed

- Consolidated complete reader appearance controls in the main settings window and reduced the floating popover to three quick adjustments.
- Made normal floating pagination more conservative for CJK text and removed line-limit truncation from reading surfaces.
- Raised safe minimum sizes for the main window, library, settings, and normal floating panel.
- Balanced office utility controls at 22% idle emphasis and 72% hover emphasis.

## [0.1.5] - 2026-07-15

### Fixed

- Rolled the normal floating panel back to the established capacity-based pagination after the multi-line pixel paginator reintroduced trailing ellipses.
- Forced normal floating text to keep its intrinsic vertical layout so constrained content clips cleanly instead of appending an ellipsis.

## [0.1.4] - 2026-07-15

### Added

- Added pixel-measured multi-line pagination for the normal floating panel, including font, line-spacing, and letter-spacing constraints.
- Added regression coverage for continuous multi-page CJK text without overlap or dropped characters.

### Changed

- Refined the floating panel into a quieter record-detail surface with reduced chrome and clearer information hierarchy.
- Reworked the menu-bar controller as a neutral local workspace control instead of an explicit reader dashboard.
- Reduced persistent visual emphasis on navigation controls while retaining hover access, search, bookmarks, chapters, and exact progress.

## [0.1.3] - 2026-07-14

### Added

- Added font family, font weight, letter spacing, search-result context, chapter information, and exact text-offset progress controls.
- Added a configurable maximum width for Super Stealth mode and a compact menu-bar control center.

### Changed

- Redesigned settings as a native two-column macOS preferences surface and completed the Chinese localization audit.
- Removed cross-page character overlap so sequential pages continue without repeated context or missing text.
- Refined floating controls, toolbar symbol semantics, and the macOS application icon.
- Aligned Super Stealth pagination and window sizing with the configured maximum width.

## [0.1.2] - 2026-07-14

### Changed

- Added adaptive Super Stealth width between the configured minimum and the current screen's safe maximum.
- Replaced estimated one-line capacity with glyph-measured pagination that prefers punctuation and paragraph boundaries.
- Added a six-character context overlap between consecutive Super Stealth pages.
- Removed visible swipe displacement, direction arrows, and sliding page transitions; Super Stealth now switches instantly and the normal panel uses only an 80 ms fade.

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
[0.1.2]: https://github.com/ZOB2077/Gridnote/releases/tag/v0.1.2
[0.1.3]: https://github.com/ZOB2077/Gridnote/releases/tag/v0.1.3
[0.1.4]: https://github.com/ZOB2077/Gridnote/releases/tag/v0.1.4
[0.1.5]: https://github.com/ZOB2077/Gridnote/releases/tag/v0.1.5
[0.1.6]: https://github.com/ZOB2077/Gridnote/releases/tag/v0.1.6
