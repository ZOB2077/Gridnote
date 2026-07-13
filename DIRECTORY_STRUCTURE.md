# Suggested Directory Structure

This is the recommended repository layout for the future Gridnote codebase.

```text
Gridnote/
├── AGENTS.md
├── README.md
├── PRODUCT_SPEC.md
├── ARCHITECTURE.md
├── TEST_PLAN.md
├── TASKS.md
├── DIRECTORY_STRUCTURE.md
├── DECISIONS/
│   └── 0001-architecture.md
├── PROMPTS/
│   └── 001-bootstrap.md
├── Docs/
│   ├── UX/
│   ├── Notes/
│   └── Fixtures-Guide.md
├── Gridnote/
│   ├── App/
│   ├── Domain/
│   ├── Persistence/
│   │   ├── Model/
│   │   ├── Repository/
│   │   └── Cache/
│   ├── Parsers/
│   │   ├── TXT/
│   │   └── EPUB/
│   ├── Library/
│   ├── Reader/
│   │   └── TextReader/
│   ├── StealthReader/
│   ├── Office/
│   ├── Settings/
│   ├── Shared/
│   │   ├── UI/
│   │   ├── Utilities/
│   │   └── Localization/
│   └── Resources/
├── GridnoteTests/
│   ├── Fixtures/
│   │   ├── TXT/
│   │   └── EPUB/
│   ├── Domain/
│   ├── Persistence/
│   ├── Parsers/
│   ├── Reader/
│   ├── StealthReader/
│   ├── Office/
│   └── Support/
└── GridnoteUITests/
    ├── Launch/
    ├── Library/
    ├── Reader/
    ├── Office/
    └── Support/
```

## Folder Intent

- Root documentation files define product, architecture, tests, and task sequencing.
- `Docs/` stores human-facing design notes and future UX artifacts.
- `Gridnote/App` stores app entry, scene coordination, and top-level state.
- `Gridnote/Domain` stores source-of-truth app types independent from UI.
- `Gridnote/Persistence` stores `SwiftData`, repositories, bookmarks, and parse-cache logic.
- `Gridnote/Parsers` stores file-format-specific parsing code behind stable interfaces.
- `Gridnote/Library` stores import and library presentation logic.
- `Gridnote/Reader` stores standard reading surfaces.
- `Gridnote/StealthReader` stores floating-reader pagination, panel, and menu bar controls.
- `Gridnote/Office` stores office shell, grid model, and disguise logic.
- `Gridnote/Settings` stores user preference UI and persistence hooks.
- `Gridnote/Shared` stores reusable UI, helpers, and localization support.
- `GridnoteTests` stores unit and integration tests with local fixtures.
- `GridnoteUITests` stores launch and interaction tests.

## Naming Guidance

- Keep directories feature-oriented rather than file-type-oriented.
- Avoid mixing parser code into view folders.
- Avoid placing persistence models inside SwiftUI views.
- Avoid large "Utils" dumping grounds. Prefer explicit helper names under `Shared/Utilities`.

## Bootstrap Expectation

The first implementation task does not need to create every leaf folder, but it should create the major folders and align Xcode groups with this structure as closely as practical.
