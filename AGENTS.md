# AGENTS.md

This repository builds `Gridnote`, a local-first macOS reading app with an office-style spreadsheet disguise.

Read this file before every task.

## Document Priority

When documents conflict, use this order:

1. `PRODUCT_SPEC.md` for user-facing behavior
2. `ARCHITECTURE.md` for technical structure
3. `DECISIONS/` for accepted architecture decisions
4. `TASKS.md` for execution sequence and task boundaries
5. `TEST_PLAN.md` for coverage and release gates
6. `README.md` and `PROMPTS/` for workflow support

If you discover a real contradiction, fix the smallest possible set of documents and explain the change in your task summary.

## Permanent Product Rules

- Support only local files in MVP.
- Support only `TXT` and `EPUB` in MVP. Reject PDF as unsupported.
- Do not add networking, cloud sync, telemetry, analytics, ads, or accounts.
- Do not add DRM support or DRM removal behavior.
- Do not add full spreadsheet compatibility, `.xlsx` fidelity, formulas, macros, or Office import/export.
- Do not use Microsoft trademarks, logos, icons, or copied proprietary visual assets.
- Do not use private macOS APIs.
- Do not add third-party dependencies in MVP without a new decision record.

## Engineering Rules

- Use `SwiftUI` first.
- Use `AppKit` only where macOS-specific behavior clearly needs it.
- Use `SwiftData` for persisted state in MVP.
- Keep parsing logic independent from UI code.
- Keep persistence logic independent from SwiftUI views.
- Keep alias metadata separate from actual metadata.
- The window title must never use the actual book title.
- All user-visible strings must be localizable.

## Scope Discipline

- Do not implement features that are merely implied by conversation history but absent from `PRODUCT_SPEC.md`.
- Do not widen a task because "it is nearby".
- If a task requires a foundational change outside its boundary, stop at the smallest correct abstraction and report the needed follow-up.
- Prefer placeholder UI over speculative full features when the task only asks for scaffolding.

## Testing Rules

Every implementation task must include one of the following:

- Automated tests that cover the change
- A precise explanation of why the change is not realistically automatable yet and a manual verification note

Required verification once the Xcode project exists:

```bash
xcodebuild -project Gridnote.xcodeproj -scheme Gridnote -destination 'platform=macOS' build
xcodebuild -project Gridnote.xcodeproj -scheme Gridnote -destination 'platform=macOS' test
```

If a task affects only one test target or one focused suite, run the narrowest useful command in addition to the full suite when practical.

## Definition Of Done

A task is done only when:

- The code builds.
- Relevant tests pass.
- The implementation stays inside the task boundary.
- User-facing behavior matches `PRODUCT_SPEC.md`.
- Architecture stays aligned with `ARCHITECTURE.md`.
- Any deviations are explicitly called out.

## Naming And Structure

Expected target names:

- `Gridnote`
- `GridnoteTests`
- `GridnoteUITests`

Expected root work areas:

- `Gridnote/App`
- `Gridnote/Domain`
- `Gridnote/Persistence`
- `Gridnote/Parsers`
- `Gridnote/Library`
- `Gridnote/Reader`
- `Gridnote/Office`
- `Gridnote/Settings`
- `Gridnote/Shared`

## Implementation Notes

- Keep `TXT` and `EPUB` on a canonical text model.
- Use a single primary window in MVP.
- Keep `OfficeWorkspace` and `ReaderWorkspace` resident after initialization so switching does not reconstruct the entire app surface.
- Do not implement a system-wide global hotkey in MVP.

## Reporting Format

At the end of each task, report:

- Changed files
- Verification commands run
- Test results
- Any deliberate omissions
- Any document updates and why they were needed
