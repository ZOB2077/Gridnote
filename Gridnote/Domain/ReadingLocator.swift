import Foundation

enum ReadingLocator: Codable, Equatable, Sendable {
    case text(chapterID: String, blockIndex: Int, intraBlockOffset: Int)
    case epub(spineItemID: String, blockIndex: Int, intraBlockOffset: Int)
}
