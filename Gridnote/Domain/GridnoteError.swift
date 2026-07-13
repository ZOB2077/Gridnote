import Foundation

enum GridnoteError: LocalizedError, Equatable {
    case unsupportedFormat(String)
    case sourceUnavailable(String)
    case bookmarkCreationFailed
    case missingBook(UUID)
    case invalidReadingLocator
    case parseFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "This file type is not supported. Choose a TXT or EPUB file."
        case .sourceUnavailable:
            return "The book file cannot be opened. Locate it again from Library."
        case .bookmarkCreationFailed:
            return "The selected file could not be retained for future access."
        case .missingBook:
            return "This book is no longer available in the library."
        case .invalidReadingLocator:
            return "The saved reading position could not be restored. The book will open from the beginning."
        case .parseFailed(let reason):
            return "The book could not be read. \(reason)"
        }
    }
}
