import Foundation
import SwiftData

public let categoryColors = ["#C2502F", "#3E7CB1", "#D9A03F", "#7A5BA6", "#3F8F7F", "#B5577E"]

/// Categories that aren't archived, in insertion order
public func unarchivedCategories(in context: ModelContext) throws -> [Category] {
    let descriptor = FetchDescriptor<Category>(
        predicate: #Predicate { !$0.isArchived },
        sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
    )
    return try context.fetch(descriptor)
}

@discardableResult
public func addCategory(named name: String, in context: ModelContext, now: Date = .now) throws -> Category? {
    let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    /// Make sure there's a name and its not "General"
    guard !name.isEmpty, name.localizedCaseInsensitiveCompare(categoryName(nil)) != .orderedSame else { return nil }
    if let existing = try unarchivedCategories(in: context).first(where: {
        $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
    }) {
        return existing
    }

    let all = try context.fetch(FetchDescriptor<Category>())
    let category = Category(
        name: name,
        colorHex: categoryColors[all.count % categoryColors.count],
        sortOrder: (all.map(\.sortOrder).max() ?? -1) + 1,
        createdAt: now
    )
    context.insert(category)
    try context.save()
    return category
}
