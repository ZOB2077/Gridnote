import XCTest
@testable import Gridnote

final class PerformanceStateTests: XCTestCase {
    func testBookSelectionPerformanceSmoke() {
        let state = AppState()
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<10_000 { state.selectBook(UUID()) }
        let average = (CFAbsoluteTimeGetCurrent() - start) / 10_000
        XCTAssertLessThan(average, 0.150)
        print("PERF book_selection_seconds=\(String(format: "%.8f", average))")
    }
}
