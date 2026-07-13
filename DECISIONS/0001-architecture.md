# ADR 0001: Single-Window Local-First Architecture With Canonical Text Model

Status: `Accepted`  
Date: `2026-07-10`

## Context

Gridnote must support three formats in MVP, switch quickly between an office disguise and a normal reader, and remain manageable for incremental Codex-driven implementation. The project also has hard scope constraints:

- Offline only
- No cloud or telemetry
- No full spreadsheet engine
- No third-party dependency requirement
- macOS-native behavior

The main risk is uncontrolled complexity. A loose architecture would make mode switching fragile and encourage UI, parsing, and persistence logic to bleed together.

## Decision

We will adopt the following architecture for MVP:

1. Use a single primary macOS window.
2. Keep `OfficeWorkspace` and `ReaderWorkspace` resident after initialization and switch visible state rather than rebuilding the full interface tree each time.
3. Normalize `TXT` and `EPUB` into a shared canonical text model.
4. Exclude PDF from the MVP and reject it at the import boundary.
5. Store app state locally with `SwiftData`.
6. Use security-scoped bookmarks for user-selected files that require persistent access.
7. Use `SwiftUI` first and `AppKit` only for platform-specific window and focus behavior.
8. Exclude system-wide global hotkeys from MVP.
9. Exclude third-party dependencies from MVP.

## Consequences

Positive:

- Mode switching can be fast and predictable.
- Parser code stays separate from view code.
- Text-based formats share one reader path.
- The application has no page-oriented document rendering path.
- Repository bootstrap stays small enough for the first Codex tasks.

Negative:

- EPUB parsing requires more custom work in MVP.
- The office shell remains intentionally limited and cannot claim spreadsheet compatibility.
- Users must convert unsupported formats to TXT or EPUB before import.
- System-wide hide or reveal shortcuts are deferred.

## Alternatives Considered

### Multi-window design

Rejected because it increases state restoration complexity, title coordination complexity, and the risk of visible flashes during switching.

### Full document import into app-managed storage

Rejected for MVP because it adds file duplication, migration, and storage-management work that is not required to ship the first version.

### Third-party EPUB parser dependency

Rejected for MVP to keep the bootstrap small and the dependency surface controlled.

### Full spreadsheet engine

Rejected because it would dominate the project and distract from the actual reading product.

## Follow-Up Rules

- Any future proposal that adds networking, third-party dependencies, global hotkeys, or a second primary window requires a new decision record.
- Any future proposal that changes the canonical text model or persistence ownership must update `ARCHITECTURE.md` and `PRODUCT_SPEC.md` together.
