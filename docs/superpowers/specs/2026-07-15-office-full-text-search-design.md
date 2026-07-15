# Office Full-Text Search Design

## Goal

Make novel full-text search visible and easy to use in the spreadsheet disguise. The existing magnifying-glass symbol in the formula bar becomes the primary search control. Search results continue to appear in the formula bar and update the shared reading position.

## Interaction

- Clicking the formula-bar magnifying glass toggles an inline search bar directly below the formula bar.
- `Command-F` opens the same search bar.
- Opening search immediately focuses the query field and selects its current contents.
- The bar contains a clear query field, Previous and Next buttons, a `current / total` result count, a short context preview, and an explicit close button.
- Return performs Next. Previous and Next wrap at the beginning and end of the book.
- Clearing the query clears result metadata without changing reading position.
- Closing the bar preserves the current query and reading position.
- A successful result is rendered in the formula bar and persists through the existing office-to-floating-reader progress synchronization.
- The feature searches only novel text. Spreadsheet disguise data remains unaffected.

## State And Architecture

`OfficeWorkspaceViewModel` owns the active query, all match ranges, and selected match index. It exposes result count text and context as read-only presentation state. A new query builds the match list once; repeated Previous and Next operations navigate that list without rescanning the document.

`OfficeWorkspaceContent` owns only presentation state: whether the bar is visible and whether the query field is focused. Both the formula-bar button and the existing notification route call one `presentFindBar()` function.

The implementation stays inside the existing office reader pipeline and adds no networking, spreadsheet search, new persistence model, or third-party dependency.

## Error And Empty States

- Empty query: navigation buttons disabled and result metadata hidden.
- No matches: display `没有匹配项`; keep the current reading position unchanged.
- No selected book: keep controls available but display `没有可搜索的书籍` after an attempted search.

## Verification

- Unit test first, next, previous, wraparound, no-match, and match-count behavior.
- Build the macOS target and run all non-UI unit tests.
- Manual QA: click the formula-bar icon, type Chinese text, navigate in both directions, verify formula-bar content and floating-reader progress synchronization, close and reopen search, and verify `Command-F` uses the same control.
- Do not run UI automation tests because this project intentionally avoids their macOS permission prompts.

## Acceptance Criteria

1. The formula-bar magnifying glass is visibly clickable and has an accessibility label and tooltip.
2. Clicking it or pressing `Command-F` opens and focuses the same search bar.
3. Chinese text can be entered without keyboard shortcuts intercepting editing keys.
4. Previous and Next show `第 X / Y 项`, wrap correctly, and update the formula-bar excerpt.
5. Office and floating-reader progress remain synchronized after a search jump.
6. Closing or clearing search never changes the current reading location.
