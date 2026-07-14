import Foundation

enum SourceStatus: String, Codable, CaseIterable, Sendable {
    case available
    case missing
    case accessDenied
    case unsupported
}
