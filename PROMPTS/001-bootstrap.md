# Prompt 001: Bootstrap The Gridnote Repository

Read these files before changing anything:

- `AGENTS.md`
- `PRODUCT_SPEC.md`
- `ARCHITECTURE.md`
- `TASKS.md`
- `TEST_PLAN.md`
- `DECISIONS/0001-architecture.md`

Implement `Task 001: Repository Bootstrap` from `TASKS.md`.

Repository state assumptions:

- The repository currently contains documentation only.
- The app does not exist yet.
- Your job is to create the initial macOS project skeleton and test scaffolding, not to implement import, parsing, or disguise logic.

Requirements:

1. Create an Xcode macOS app project named `Gridnote`.
2. Create targets named `Gridnote`, `GridnoteTests`, and `GridnoteUITests`.
3. Use the newest locally available macOS SDK and document the exact deployment target you choose.
4. Create root source folders and matching Xcode groups for:
   - `App`
   - `Domain`
   - `Persistence`
   - `Parsers`
   - `Library`
   - `Reader`
   - `Office`
   - `Settings`
   - `Shared`
5. Add a SwiftUI app entry point.
6. Add `AppShellView` that launches into `Office` mode by default.
7. Add placeholder views named exactly:
   - `OfficeWorkspaceView`
   - `ReaderWorkspaceView`
   - `LibraryView`
   - `SettingsView`
8. Add a minimal app state type that can represent `office` and `reader` workspace modes.
9. Do not implement file import, persistence, or parsers yet.
10. Add one smoke UI test that verifies the office workspace is visible on launch.

Acceptance criteria:

- `xcodebuild -list` succeeds.
- The app builds successfully.
- Tests pass.
- Launching the app shows the office workspace placeholder first.
- The resulting structure is aligned with `DIRECTORY_STRUCTURE.md` as closely as practical for a first commit.

Constraints:

- Stay inside `Task 001`.
- Do not add dependencies.
- Do not modify the product scope.
- Do not create speculative features outside the bootstrap boundary.

Report back with:

- Changed files
- The deployment target selected
- Verification commands run
- Test results
- Any deviations from the docs and why they were necessary
