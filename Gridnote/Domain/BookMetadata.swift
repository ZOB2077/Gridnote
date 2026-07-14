import Foundation

struct BookMetadata: Codable, Equatable, Sendable {
    var title: String
    var author: String?
    var language: String?
    var sourceFilename: String?

    init(
        title: String,
        author: String? = nil,
        language: String? = nil,
        sourceFilename: String? = nil
    ) {
        self.title = title
        self.author = author
        self.language = language
        self.sourceFilename = sourceFilename
    }
}
