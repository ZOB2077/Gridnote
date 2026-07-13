import Foundation

struct BookDocument: Codable, Equatable, Sendable {
    let id: UUID
    let format: BookFormat
    let metadata: BookMetadata
    let chapters: [BookChapter]
    let toc: [TOCEntry]
}

struct BookChapter: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let textBlocks: [TextBlock]
}

struct TextBlock: Codable, Equatable, Sendable {
    let id: String
    let text: String
}

struct TOCEntry: Codable, Equatable, Sendable {
    let title: String
    let chapterID: String
    let depth: Int
}
