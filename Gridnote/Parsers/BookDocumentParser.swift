import Foundation

protocol BookDocumentParser {
    func parse(url: URL, metadata: BookMetadata, id: UUID) throws -> BookDocument
}
