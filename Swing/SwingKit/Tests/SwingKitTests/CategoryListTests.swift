import Foundation
import SwiftData
import Testing
import SwingKit

struct CategoryListTests {
    let context: ModelContext

    init() throws {
        context = ModelContext(try SwingStore.makeContainer(inMemory: true))
    }

    @Test func addedCategoriesAppearInOrderWithColors() throws {
        try addCategory(named: "Writing", in: context)
        try addCategory(named: "Email", in: context)

        let categories = try unarchivedCategories(in: context)
        #expect(categories.map(\.name) == ["Writing", "Email"])
        #expect(categories.map(\.sortOrder) == [0, 1])
        #expect(categories.map(\.colorHex) == Array(categoryColors.prefix(2)))
    }

    @Test func nameIsTrimmed() throws {
        let category = try addCategory(named: "  Writing \n", in: context)
        #expect(category?.name == "Writing")
    }

    @Test func blankNameAddsNothing() throws {
        #expect(try addCategory(named: "   ", in: context) == nil)
        #expect(try unarchivedCategories(in: context).isEmpty)
    }

    @Test func generalAddsNothing() throws {
        #expect(try addCategory(named: "general", in: context) == nil)
        #expect(try unarchivedCategories(in: context).isEmpty)
    }

    @Test func sameNameReturnsExistingCategory() throws {
        let first = try addCategory(named: "Writing", in: context)
        let second = try addCategory(named: "writing", in: context)

        #expect(second === first)
        #expect(try unarchivedCategories(in: context).count == 1)
    }

    @Test func colorsRepeatAfterTheLast() throws {
        for index in 0...categoryColors.count {
            try addCategory(named: "Category \(index)", in: context)
        }
        #expect(try unarchivedCategories(in: context).last?.colorHex == categoryColors[0])
    }

    @Test func archivedCategoriesAreHiddenButStillCount() throws {
        let old = try #require(try addCategory(named: "Old", in: context))
        old.isArchived = true
        try context.save()

        let new = try addCategory(named: "New", in: context)

        #expect(try unarchivedCategories(in: context).map(\.name) == ["New"])
        #expect(new?.sortOrder == 1)
        #expect(new?.colorHex == categoryColors[1])
    }

    @Test func archivedNameCanBeAddedAgain() throws {
        let old = try #require(try addCategory(named: "Writing", in: context))
        old.isArchived = true
        try context.save()

        let new = try addCategory(named: "Writing", in: context)

        #expect(new !== old)
        #expect(try unarchivedCategories(in: context).map(\.name) == ["Writing"])
    }
}
