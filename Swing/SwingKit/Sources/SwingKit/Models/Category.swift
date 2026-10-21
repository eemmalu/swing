import Foundation
import SwiftData

@Model
public final class Category {
    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "#8E8E93"
    /// Position in the category picker, lowest first
    public var sortOrder: Int = 0
    public var isArchived: Bool = false
    public var createdAt: Date = Date.now

    /// Sessions tagged with this category. Deleting the category clears their category, so they show as "General"
    @Relationship(deleteRule: .nullify, inverse: \Session.category)
    public var sessions: [Session]? = []

    public init(name: String, colorHex: String = "#8E8E93", sortOrder: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
