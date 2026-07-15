# Gridnote

[![macOS CI](https://github.com/ZOB2077/Gridnote/actions/workflows/ci.yml/badge.svg)](https://github.com/ZOB2077/Gridnote/actions/workflows/ci.yml)
![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-111111)
![Swift](https://img.shields.io/badge/Swift-6.0-F05138)
![License](https://img.shields.io/badge/license-source--available%20non--commercial-2F855A)

> A local-first macOS reader with an original office-workspace presentation and a privacy-focused floating reader.

Gridnote keeps books, reading progress, aliases, bookmarks, and settings on the Mac. Its primary workspace resembles a compact data workbook populated exclusively with synthetic demo records, while the floating reader provides a minimal, resizable reading surface for short sessions. It is designed for personal reading, not as an Excel replacement or a content distribution service.

**Status:** `v0.1.6` personal-Mac preview. The application is functional and packaged for personal use without notarization.

## Highlights

- Local TXT and non-DRM EPUB import. TXT decoding supports UTF-8, UTF-16, GB18030, and common fallback encodings.
- Persistent reading location, full-text search, bookmarks, chapter navigation, and per-book aliases.
- A dense, original office workspace containing synthetic demo data, with novel excerpts shown in the formula bar rather than the grid.
- Floating reader with page-based layout, transparency controls, precise reading progress, typography controls, and an optional borderless Super Stealth mode.
- Bidirectional progress sync: navigating in the office formula bar or floating reader continues from the same location.
- Configurable shortcut profile. Defaults are `F7` previous, `F8` next, and `F9` show or hide the floating reader.
- No accounts, networking, analytics, cloud sync, DRM removal, or online catalog.

## Requirements

- macOS 26 or later.
- Apple Silicon is the currently packaged release architecture.
- Xcode 26 or later. Local release verification currently uses Xcode 27 beta.

## Install

Download the latest `Gridnote-macOS.dmg` or `Gridnote-macOS.zip` from [Releases](https://github.com/ZOB2077/Gridnote/releases). Move `Gridnote.app` to Applications and open it.

The preview build is ad-hoc signed, not notarized. If macOS blocks the first launch, use Finder's **Open** action or allow the app in **System Settings > Privacy & Security**. Do not bypass Gatekeeper for builds from untrusted sources.

## Use

1. Launch Gridnote. The default surface is the office-style data workspace.
2. Select the library icon and import a TXT or EPUB file.
3. Open the floating reader from the toolbar or use `F9`.
4. Navigate with `F7` and `F8`. When the floating reader is hidden, the same shortcuts move the formula-bar excerpt while Gridnote is focused.
5. Enable Super Stealth mode in settings when only text should be visible. Its display width and height can be adjusted down to a single line.

The office workspace is intentionally limited to presentation and lightweight cell editing. It does not claim XLSX compatibility or implement Excel formulas, macros, or import/export.

## Build From Source

```bash
git clone https://github.com/ZOB2077/Gridnote.git
cd Gridnote
open Gridnote.xcodeproj
```

Or build from Terminal with the configured Xcode:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project Gridnote.xcodeproj -scheme Gridnote \
  -destination 'platform=macOS,arch=arm64' build
```

Run the unit test suite:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project Gridnote.xcodeproj -scheme Gridnote \
  -destination 'platform=macOS' -parallel-testing-enabled NO \
  -skip-testing:GridnoteUITests test
```

UI automation is intentionally excluded from the default command because macOS can request local permissions during test launches. See [TEST_PLAN.md](TEST_PLAN.md) for manual verification guidance.

## Supported Formats

| Format | Support | Notes |
| --- | --- | --- |
| TXT | Supported | Local text files with encoding detection and chapter heuristics. |
| EPUB | Supported | Non-DRM EPUB text, metadata, spine, and table of contents. Complex CSS and media are not reproduced. |
| PDF | Not supported | Convert to TXT or EPUB before import. |
| DRM-protected books | Not supported | Gridnote does not remove or bypass DRM. |

## Privacy And Safety

- Reading content remains local to the Mac.
- Built-in office tables are deterministic synthetic fixtures and contain no customer or business records.
- Gridnote does not attempt to bypass macOS protections, device management, screen recording, or monitoring software.
- The office presentation uses original assets and interaction patterns; it is not affiliated with Microsoft, WPS, or any office-suite vendor.
- See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md) for technical and distribution limits.

## Project Documentation

- [Product specification](PRODUCT_SPEC.md)
- [Architecture](ARCHITECTURE.md)
- [Test plan](TEST_PLAN.md)
- [Changelog](CHANGELOG.md)
- [Release notes](RELEASE_NOTES.md)
- [Contributing](CONTRIBUTING.md)
- [Support](SUPPORT.md)
- [Security policy](SECURITY.md)

## License And Commercial Use

Gridnote is **source-available**, not OSI open source. The project is licensed under the [Gridnote Source-Available Non-Commercial License v1.0](LICENSE). Personal, educational, research, and other non-commercial use is permitted under its terms.

Commercial distribution, paid services, monetized derivatives, white-label use, and similar commercial use require a separate written agreement. Contact [ZOB2077](https://github.com/ZOB2077) to discuss a commercial license.

## Acknowledgements

The floating-reader feature was designed with reference to the MIT-licensed [StealthReader](https://github.com/mx3353672833-debug/StealthReader-moyu-reader-mac) project. Gridnote uses an independent implementation. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
