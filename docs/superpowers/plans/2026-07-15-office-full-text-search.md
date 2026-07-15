# Office Full-Text Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the spreadsheet formula-bar magnifying glass into a focused novel full-text search control with exact match navigation and shared progress updates.

**Architecture:** Add a pure `OfficeExcerptSearchSession` that indexes exact query ranges across canonical `TextBlock` values and owns selection navigation. `OfficeWorkspaceViewModel` applies selected matches to the existing excerpt/progress pipeline, while `OfficeWorkspaceContent` owns only bar visibility and `FocusState`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Foundation, XCTest; no third-party dependencies.

## Global Constraints

- Search only novel text; never search or mutate spreadsheet disguise data.
- Clicking the formula-bar magnifying glass and pressing `Command-F` must open the same control.
- Search jumps must use the existing office-to-floating-reader progress synchronization.
- Clearing or closing search must not alter reading position.
- Do not run UI automation tests; use unit tests and manual macOS QA.

---

### Task 1: Exact Office Search Session

**Files:**
- Modify: `Gridnote/Office/OfficeWorkspaceView.swift:455-690`
- Test: `GridnoteTests/Office/ExcerptInjectorTests.swift`

**Interfaces:**
- Consumes: `[TextBlock]`, current global block index, query string, `OfficeExcerptSearchDirection`.
- Produces: `OfficeExcerptSearchMatch` with `blockIndex`, `characterOffset`, `ordinal`, `total`, and `context`; `OfficeWorkspaceViewModel.searchResultText`; `OfficeWorkspaceViewModel.searchContext`.

- [ ] **Step 1: Write failing exact-navigation tests**

Add tests proving that three occurrences, including two in one block, return ordinals `1`, `2`, `3`, that Previous/Next wrap, and that no-match leaves the current selection absent:

```swift
func testOfficeSearchSessionNavigatesEveryOccurrenceAndWraps() {
    var session = OfficeExcerptSearchSession()
    let blocks = [
        TextBlock(id: "one", text: "目标甲，目标乙。"),
        TextBlock(id: "two", text: "结尾目标丙。")
    ]

    let first = session.navigate(in: blocks, query: "目标", currentBlockIndex: 0, direction: .next)
    let second = session.navigate(in: blocks, query: "目标", currentBlockIndex: 0, direction: .next)
    let third = session.navigate(in: blocks, query: "目标", currentBlockIndex: 0, direction: .next)
    let wrapped = session.navigate(in: blocks, query: "目标", currentBlockIndex: 1, direction: .next)

    XCTAssertEqual([first?.ordinal, second?.ordinal, third?.ordinal, wrapped?.ordinal], [1, 2, 3, 1])
    XCTAssertEqual(first?.total, 3)
    XCTAssertNotEqual(first?.characterOffset, second?.characterOffset)
}
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild \
  -project Gridnote.xcodeproj -scheme Gridnote -destination 'platform=macOS' \
  -parallel-testing-enabled NO -skip-testing:GridnoteUITests \
  -only-testing:GridnoteTests/ExcerptInjectorTests test
```

Expected: compile failure because `OfficeExcerptSearchSession` and `OfficeExcerptSearchMatch` do not exist.

- [ ] **Step 3: Implement exact match indexing and navigation**

Create value types in `OfficeWorkspaceView.swift`:

```swift
struct OfficeExcerptSearchMatch: Equatable {
    let blockIndex: Int
    let characterOffset: Int
    let ordinal: Int
    let total: Int
    let context: String
}

struct OfficeExcerptSearchSession {
    private struct Entry {
        let blockIndex: Int
        let range: NSRange
    }

    private var query = ""
    private var matches: [Entry] = []
    private var selectedIndex: Int?

    mutating func navigate(
        in blocks: [TextBlock],
        query: String,
        currentBlockIndex: Int,
        direction: OfficeExcerptSearchDirection
    ) -> OfficeExcerptSearchMatch? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !blocks.isEmpty else {
            clear()
            return nil
        }
        if self.query.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame {
            self.query = trimmed
            matches = blocks.enumerated().flatMap { blockIndex, block in
                let text = block.text as NSString
                var entries: [Entry] = []
                var location = 0
                while location < text.length {
                    let range = text.range(
                        of: trimmed,
                        options: [.caseInsensitive, .diacriticInsensitive],
                        range: NSRange(location: location, length: text.length - location)
                    )
                    guard range.location != NSNotFound, range.length > 0 else { break }
                    entries.append(Entry(blockIndex: blockIndex, range: range))
                    location = range.location + range.length
                }
                return entries
            }
            selectedIndex = nil
        }
        guard !matches.isEmpty else { return nil }

        let index: Int
        if let selectedIndex {
            let delta: Int = switch direction {
            case .next: 1
            case .previous: -1
            }
            index = (selectedIndex + delta + matches.count) % matches.count
        } else if direction == .next {
            index = matches.firstIndex { $0.blockIndex >= currentBlockIndex } ?? 0
        } else {
            index = matches.lastIndex { $0.blockIndex <= currentBlockIndex } ?? (matches.count - 1)
        }
        selectedIndex = index
        let entry = matches[index]
        let text = blocks[entry.blockIndex].text as NSString
        let start = max(0, entry.range.location - 24)
        let end = min(text.length, entry.range.location + entry.range.length + 32)
        let contextRange = text.rangeOfComposedCharacterSequences(
            for: NSRange(location: start, length: end - start)
        )
        return OfficeExcerptSearchMatch(
            blockIndex: entry.blockIndex,
            characterOffset: entry.range.location,
            ordinal: index + 1,
            total: matches.count,
            context: text.substring(with: contextRange).replacingOccurrences(of: "\n", with: " ")
        )
    }

    mutating func clear() {
        query = ""
        matches = []
        selectedIndex = nil
    }
}
```

Index non-overlapping, case/diacritic-insensitive matches. On a new query, Next starts at the first match at or after the current block; Previous starts before the current location and wraps. Context includes up to 24 characters before and 32 after the selected match with line breaks flattened.

- [ ] **Step 4: Integrate the session into `OfficeWorkspaceViewModel`**

Add:

```swift
@Published private(set) var searchResultText = ""
@Published private(set) var searchContext = ""
private var searchSession = OfficeExcerptSearchSession()

@discardableResult
func searchExcerpt(for query: String, direction: OfficeExcerptSearchDirection) -> Bool

func clearSearch()
```

On success, call `applyExcerpt(startingAt: match.blockIndex, intraBlockOffset: match.characterOffset)` so existing progress persistence and notifications remain authoritative. Format result text with localized `Result %lld of %lld`.

- [ ] **Step 5: Run focused tests and verify GREEN**

Run the command from Step 2. Expected: all `ExcerptInjectorTests` pass.

- [ ] **Step 6: Commit the search state machine**

```bash
git add Gridnote/Office/OfficeWorkspaceView.swift GridnoteTests/Office/ExcerptInjectorTests.swift
git commit -m "Add exact office full-text search"
```

---

### Task 2: Formula-Bar Search Control

**Files:**
- Modify: `Gridnote/Office/OfficeWorkspaceView.swift:10-330`
- Modify: `Gridnote/Localizable.xcstrings`
- Modify: `CHANGELOG.md`
- Modify: `README.md`
- Modify: `RELEASE_NOTES.md`
- Modify: `SECURITY.md`
- Modify: `Gridnote.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `OfficeWorkspaceViewModel.searchExcerpt`, `clearSearch`, `searchResultText`, and `searchContext` from Task 1.
- Produces: one `presentFindBar()` path used by both the formula-bar button and `.gridnoteOfficeSearchRequested`.

- [ ] **Step 1: Add focus and presentation state**

Add `@FocusState private var isFindFieldFocused: Bool` and implement:

```swift
private func presentFindBar() {
    isFindBarPresented = true
    Task { @MainActor in
        await Task.yield()
        isFindFieldFocused = true
    }
}

private func dismissFindBar() {
    isFindFieldFocused = false
    isFindBarPresented = false
}
```

Route the existing `Command-F` notification through `presentFindBar()`.

- [ ] **Step 2: Make the formula-bar icon interactive**

Replace the decorative icon with:

```swift
Button(action: presentFindBar) {
    Image(systemName: "magnifyingglass")
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
}
.buttonStyle(.plain)
.help("全文搜索")
.accessibilityLabel("全文搜索")
```

Keep the original formula-bar spacing and neutral styling.

- [ ] **Step 3: Upgrade the inline find bar**

Bind the field to `isFindFieldFocused`, use Return for Next, show `viewModel.searchResultText`, render up to two lines of `viewModel.searchContext`, disable navigation for an empty trimmed query, clear view-model search state when the query becomes empty, and use `dismissFindBar()` for Close.

- [ ] **Step 4: Build and run all non-UI tests**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild \
  -project Gridnote.xcodeproj -scheme Gridnote -destination 'platform=macOS' \
  -parallel-testing-enabled NO -skip-testing:GridnoteUITests test
```

Expected: all tests pass with zero failures.

- [ ] **Step 5: Perform manual QA**

Build and open the app. Verify the formula-bar icon opens and focuses search, Chinese text entry works, Previous/Next update `第 X / Y 项`, matching text appears in the formula bar, `F7/F8` and the floating reader continue from the searched position, Close preserves position, and `Command-F` opens the same bar.

- [ ] **Step 6: Package and verify the release**

Bump to `v0.1.9` build `10`, update release documents, build arm64 Release, ad-hoc sign, replace `/Applications/Gridnote.app`, regenerate ZIP/DMG/SHA256 files, verify signature and checksums, push `main`, tag `v0.1.9`, and create a release while confirming repository visibility remains `PRIVATE`.

- [ ] **Step 7: Commit the UI and release changes**

```bash
git add Gridnote/Office/OfficeWorkspaceView.swift Gridnote/Localizable.xcstrings \
  Gridnote.xcodeproj/project.pbxproj CHANGELOG.md README.md RELEASE_NOTES.md SECURITY.md
git commit -m "Expose office full-text search"
```
