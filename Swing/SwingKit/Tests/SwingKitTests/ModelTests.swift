import Foundation
import SwiftData
import Testing
import SwingKit

struct ModelTests {
    let context: ModelContext

    init() throws {
        let container = try ModelContainer(
            for: Category.self, Session.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    @Test func sessionIsSavedAndLoaded() throws {
        let start = Date(timeIntervalSinceReferenceDate: 9 * 3600)
        let session = Session(start: start, note: "Logo sketches", deviceName: "Test Mac")
        context.insert(session)
        try context.save()

        let loaded = try context.fetch(FetchDescriptor<Session>())
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == session.id)
        #expect(loaded.first?.start == start)
        #expect(loaded.first?.end == nil)
        #expect(loaded.first?.category == nil)
        #expect(loaded.first?.note == "Logo sketches")
        #expect(loaded.first?.deviceName == "Test Mac")
    }

    @Test func newItemsGetDifferentIDs() {
        let first = Category(name: "Design")
        let second = Category(name: "Design")
        #expect(first.id != second.id)
    }

    @Test func sessionAppearsInItsCategory() throws {
        let design = Category(name: "Design", colorHex: "#F2A65A")
        context.insert(design)
        let session = Session(start: .now, category: design, deviceName: "Test Mac")
        context.insert(session)
        try context.save()

        #expect(design.sessions?.map(\.id) == [session.id])
    }

    @Test func deletingCategoryKeepsItsSessions() throws {
        let design = Category(name: "Design")
        context.insert(design)
        let session = Session(start: .now, category: design, deviceName: "Test Mac")
        context.insert(session)
        try context.save()

        context.delete(design)
        try context.save()

        let loaded = try context.fetch(FetchDescriptor<Session>())
        #expect(loaded.count == 1)
        #expect(loaded.first?.category == nil)
    }
}
