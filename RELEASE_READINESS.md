# Gridnote MVP Release Readiness

Date: 2026-07-13

## Automated Evidence

- Debug app target builds with Swift 6, macOS deployment target 26.0, and macOS 27.0 SDK.
- Required offline fixtures exist for TXT and EPUB, including corrupt inputs.
- Unit coverage includes parsing, persistence, progress, aliases, settings, office grid projection, and error paths.
- UI coverage includes office launch, import affordance, library search/detail/read, missing-source re-link visibility, TXT restore, workspace switching, safe titles, and settings alias flow.
- Unit tests pass locally, including parser, persistence, office projection, floating-reader, and progress-synchronization coverage.
- GitHub CI runs functional unit coverage and explicitly skips only the host-dependent 20MB wall-clock assertion; that measurement is retained below as local release evidence.
- UI automation explicitly terminates each launched application during teardown, including relaunch scenarios, to prevent stale settings or reader windows from blocking the Xcode test session.
- Core implementation contains no networking client, analytics SDK, account flow, or cloud dependency.

## Performance Smoke Results

Measured on the local Apple Silicon development Mac using the Debug configuration:

| Check | Result | Soft target | Status |
|---|---:|---:|---|
| Cold launch to office-ready marker | 0.2281 s | < 2.0 s | Pass |
| Parse 20MB UTF-8 TXT | 3.2086 s | < 5.0 s | Pass |
| Cached reopen of 20MB TXT | 0.0568 s | Informational | Pass |
| Workspace state transition | 0.00000163 s | < 0.150 s | Pass |

The workspace transition measurement covers the synchronous state path. Manual inspection confirmed the visible switch has no intentional animation or loading screen.

## Manual Acceptance

- [x] Office mode is the default launch surface.
- [x] Toolbar, formula bar, headers, grid, tabs, and status area are visually present.
- [x] Office shell reads as an original office data tool and does not copy Microsoft assets.
- [x] Formula-bar editing persists through SwiftData repository tests.
- [x] TXT content appears in the floating reader and office formula-bar projection.
- [x] `F7`/`F8` navigation and `F9` floating-reader visibility preserve a disguise window title.
- [x] Office and floating-reader navigation synchronize through a shared reading location.
- [x] TXT and EPUB fixture parsing is covered by automated tests.
- [x] PDF is rejected as unsupported and has no reader implementation.
- [x] Missing-source state exposes the re-link action in the library.
- [x] Reader text color, opacity, density, and floating-panel appearance settings are present.

## Release Decision

All twelve baseline tasks and the subsequent office/floating-reader refinements are complete. The repository is ready as a development MVP and personal-Mac preview build. Developer ID signing, notarization, sandbox entitlement verification, and App Store packaging remain separate release-engineering work.
