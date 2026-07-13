import Foundation
import SwiftData

@Model
final class BookRecord {
    @Attribute(.unique) var id: UUID
    var sourcePath: String
    var sourceBookmarkData: Data?
    var fileFingerprint: String?
    var detectedTitle: String
    var detectedAuthor: String?
    var detectedLanguage: String?
    var sourceFilename: String?
    var formatRawValue: String
    var sourceStatusRawValue: String
    var parseStatusRawValue: String
    var createdAt: Date
    var lastOpenedAt: Date?

    init(
        id: UUID = UUID(),
        metadata: BookMetadata,
        sourcePath: String,
        format: BookFormat,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sourcePath = sourcePath
        self.sourceBookmarkData = nil
        self.fileFingerprint = nil
        self.detectedTitle = metadata.title
        self.detectedAuthor = metadata.author
        self.detectedLanguage = metadata.language
        self.sourceFilename = metadata.sourceFilename
        self.formatRawValue = format.rawValue
        self.sourceStatusRawValue = SourceStatus.available.rawValue
        self.parseStatusRawValue = "unparsed"
        self.createdAt = createdAt
        self.lastOpenedAt = nil
    }

    var format: BookFormat {
        get { BookFormat(rawValue: formatRawValue) ?? .txt }
        set { formatRawValue = newValue.rawValue }
    }

    var sourceStatus: SourceStatus {
        get { SourceStatus(rawValue: sourceStatusRawValue) ?? .missing }
        set { sourceStatusRawValue = newValue.rawValue }
    }

    var metadata: BookMetadata {
        BookMetadata(
            title: detectedTitle,
            author: detectedAuthor,
            language: detectedLanguage,
            sourceFilename: sourceFilename
        )
    }
}
