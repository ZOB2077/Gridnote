import XCTest
@testable import Gridnote

final class ExcerptInjectorTests: XCTestCase {
    func testInjectsConsecutiveBlocksIntoOfficeRowsWithoutMutatingGrid() {
        let blocks = (0..<7).map { TextBlock(id: "b\($0)", text: "Paragraph \($0)") }
        let excerpt = ExcerptInjector.inject(blocks: blocks, startBlockIndex: 1, rowCount: 3)
        XCTAssertEqual(excerpt.valuesByRow, [1: "Paragraph 1", 2: "Paragraph 2", 3: "Paragraph 3"])
        XCTAssertEqual(excerpt.nextBlockIndex, 4)
        XCTAssertEqual(excerpt.startBlockIndex, 1)
    }

    func testClampsStartAndPreservesLongRows() {
        let blocks = [TextBlock(id: "only", text: String(repeating: "a", count: 20))]
        let excerpt = ExcerptInjector.inject(blocks: blocks, startBlockIndex: 99, rowCount: 5)
        XCTAssertEqual(excerpt.valuesByRow[1], String(repeating: "a", count: 20))
        XCTAssertNil(excerpt.nextBlockIndex)
    }

    func testMapsChapterLocationsToAndFromFlattenedBlocks() {
        let chapters = [
            ExcerptChapterIndex(id: "chapter-1", startBlockIndex: 0),
            ExcerptChapterIndex(id: "chapter-2", startBlockIndex: 3),
            ExcerptChapterIndex(id: "chapter-3", startBlockIndex: 7)
        ]

        XCTAssertEqual(
            ExcerptPositionMapper.globalBlockIndex(chapterID: "chapter-2", blockIndex: 2, chapters: chapters, totalBlockCount: 9),
            5
        )
        XCTAssertEqual(
            ExcerptPositionMapper.location(forGlobalBlockIndex: 8, chapters: chapters),
            ExcerptBlockLocation(chapterID: "chapter-3", blockIndex: 1)
        )
    }

    func testPrivacyMaskUsesPlausibleOperationsNotesAndRepeatsPredictably() {
        let first = OfficeExcerptMasker.value(forRow: 1)
        XCTAssertFalse(first.isEmpty)
        XCTAssertNotEqual(first, "Paragraph 1")
        XCTAssertEqual(first, OfficeExcerptMasker.value(forRow: 6))
    }
}
