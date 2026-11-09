import Foundation
import SwiftData

@Model
public final class SessionBreak {
    public var id: UUID = UUID()
    public var start: Date = Date.now
    /// `nil` while paused
    public var end: Date?
    public var session: Session?

    public init(start: Date, end: Date? = nil) {
        self.start = start
        self.end = end
    }
}
