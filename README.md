# Gridnote Codex Starter Pack

This package is the implementation baseline for `Gridnote`, a local-first macOS novel reader with an office-style spreadsheet disguise. It contains the product and architecture contract plus the initial Xcode project skeleton for Codex-driven implementation.

The package is deliberately narrow:

- Personal Mac use only.
- Local files only.
- Supported input formats in MVP: `TXT` and `EPUB`.
- Implementation baseline: `Swift 6`, `SwiftUI`, `SwiftData`, and `AppKit` only where macOS-specific behavior requires it.
- No networking, cloud sync, telemetry, DRM handling, online bookstores, or full spreadsheet compatibility in MVP.

## Included Files

- `PRODUCT_SPEC.md`
- `ARCHITECTURE.md`
- `AGENTS.md`
- `TEST_PLAN.md`
- `TASKS.md`
- `DIRECTORY_STRUCTURE.md`
- `DECISIONS/0001-architecture.md`
- `PROMPTS/001-bootstrap.md`
- `RELEASE_READINESS.md`
- `KNOWN_LIMITATIONS.md`
- `RELEASE_NOTES.md`
- `THIRD_PARTY_NOTICES.md`
- `LICENSE` (MIT)
- `Fixtures/`
- `Scripts/generate_fixtures.py`

## How To Use

1. Treat `AGENTS.md` as the standing instruction file that Codex reads before every task.
2. Treat `PRODUCT_SPEC.md` as the source of truth for user-facing behavior.
3. Treat `ARCHITECTURE.md` and `DECISIONS/0001-architecture.md` as the source of truth for code structure and technical boundaries.
4. Execute tasks in `TASKS.md` in order unless a later document explicitly permits parallel work.
5. Open `Gridnote.xcodeproj` in Xcode and continue with the next incomplete task after verifying the current baseline.

The project targets macOS `26.0`, uses Swift `6.0`, and is configured against the locally available macOS `27.0` SDK. The current implementation covers local TXT/EPUB import and reading, progress restoration, a searchable library, a lightweight spreadsheet-style office shell, and a menu-bar-controlled floating reader. PDF is intentionally unsupported.

## Implementation Status

Tasks 001 through 012 are complete. The MVP includes local TXT and EPUB reading, progress restore, an alias-first library, a lightweight office disguise, workspace switching, a transparent floating reader, menu bar controls, settings, offline release fixtures, and release-readiness documentation.

Manual visual verification was completed on macOS 27 after Task 009. The visible hierarchy reads as a credible office data sheet at normal window size, and no Microsoft trademarks or proprietary assets are used.

Task 010 manual and UI verification confirmed focused shortcut switching, office return behavior, reading-position continuity, and the generic `Operations Dashboard.xlsx` window title.

Final verification includes 33 passing unit tests and 9 macOS UI automation tests. UI tests explicitly terminate every launched app instance so settings, reader, floating-reader, and relaunch flows do not leave the test runner waiting on a stale application.

## Recommended Working Order

1. Bootstrap the macOS project and test targets.
2. Establish domain models and persistence.
3. Implement file import and bookmark-based file access.
4. Implement the canonical text pipeline for `TXT` and `EPUB`.
5. Add the standard reading experience.
6. Add the office shell and disguise-specific reading presentation.
7. Finish hardening, tests, and packaging.

## Repo Discipline

- Do not widen scope during implementation.
- Do not add third-party dependencies in MVP without an explicit architecture decision.
- Do not copy Microsoft trademarks, icons, or proprietary visual assets.
- Do not build a fake "Excel clone". Build a credible original office-like shell with limited editing.

## Definition Of Ready

The implementation is ready for the next Codex task when:

- The user agrees with the narrowed MVP.
- `Task 001` builds and its tests pass.
- The next task is executed from `TASKS.md` in order.

## Definition Of Done For The Starter Pack

The starter pack is complete when:

- All documents use the same scope and terminology.
- Every task has explicit boundaries and acceptance criteria.
- Build and test expectations are defined even before the app exists.
- The bootstrap prompt can be pasted into Codex without extra explanation.
- The implementation through Task 012 builds; all 33 unit tests and all 9 UI automation tests pass.
