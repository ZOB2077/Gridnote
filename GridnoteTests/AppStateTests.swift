import XCTest
@testable import Gridnote

final class AppStateTests: XCTestCase {
    func testSelectingBookUpdatesCurrentBook() {
        let state = AppState()
        let bookID = UUID()
        state.selectBook(bookID)
        XCTAssertEqual(state.selectedBookID, bookID)
    }
}
