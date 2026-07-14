import XCTest
@testable import Gridnote

final class ReadingLocatorTests: XCTestCase {
    func testAllLocatorCasesRoundTripThroughCodable() throws {
        let locators: [ReadingLocator] = [
            .text(chapterID: "chapter-1", blockIndex: 2, intraBlockOffset: 14),
            .epub(spineItemID: "item-3", blockIndex: 5, intraBlockOffset: 0)
        ]

        for locator in locators {
            let data = try JSONEncoder().encode(locator)
            let decoded = try JSONDecoder().decode(ReadingLocator.self, from: data)
            XCTAssertEqual(decoded, locator)
        }
    }
}
