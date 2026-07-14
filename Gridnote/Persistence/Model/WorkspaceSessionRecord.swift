import Foundation
import SwiftData

@Model
final class WorkspaceSessionRecord {
    @Attribute(.unique) var id: UUID
    var activeBookID: UUID?
    var modeRawValue: String
    var windowWidth: Double
    var windowHeight: Double
    var lastUpdatedAt: Date

    init(
        id: UUID = UUID(),
        activeBookID: UUID? = nil,
        modeRawValue: String = "office",
        windowWidth: Double = 900,
        windowHeight: Double = 640,
        lastUpdatedAt: Date = .now
    ) {
        self.id = id
        self.activeBookID = activeBookID
        self.modeRawValue = modeRawValue
        self.windowWidth = windowWidth
        self.windowHeight = windowHeight
        self.lastUpdatedAt = lastUpdatedAt
    }
}
