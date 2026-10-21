import Foundation
import SwiftData

@Model
public final class Session {
    public var id: UUID = UUID()
    public var start: Date = Date.now
    /// `nil` while the session is running
    public var end: Date?
    /// `nil` means the default category, shown as "General"
    public var category: Category?
    public var note: String?
    /// The device the session was tracked on (mac or iphone)
    public var deviceName: String = ""

    public init(start: Date, end: Date? = nil, category: Category? = nil, note: String? = nil, deviceName: String) {
        self.start = start
        self.end = end
        self.category = category
        self.note = note
        self.deviceName = deviceName
    }
}
