import Foundation
import SwiftData
import Testing
import SwingKit

final class TestClock {
    var now = Date(timeIntervalSinceReferenceDate: 9 * 3600)

    func advance(minutes: Double) {
        now += minutes * 60
    }
}

struct TrackingServiceTests {
    let context: ModelContext
    let clock = TestClock()

    init() throws {
        context = ModelContext(try SwingStore.makeContainer(inMemory: true))
    }

    func makeService() throws -> TrackingService {
        let clock = clock
        return try TrackingService(context: context, deviceName: "Test Mac", now: { clock.now })
    }

    func allSessions() throws -> [Session] {
        try context.fetch(FetchDescriptor<Session>(sortBy: [SortDescriptor(\.start)]))
    }

    @Test func startsStopped() throws {
        let service = try makeService()
        #expect(service.current == nil)
        #expect(service.selectedCategory == nil)
        #expect(!service.isRunning)
    }

    @Test func startCreatesRunningSession() throws {
        let service = try makeService()
        try service.start()

        let sessions = try allSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first === service.current)
        #expect(sessions.first?.start == clock.now)
        #expect(sessions.first?.end == nil)
        #expect(sessions.first?.category == nil)
        #expect(sessions.first?.deviceName == "Test Mac")
        #expect(service.isRunning)
    }

    @Test func stopEndsSession() throws {
        let service = try makeService()
        try service.start()
        clock.advance(minutes: 90)
        try service.stop()

        let sessions = try allSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.end == clock.now)
        #expect(service.current == nil)
    }

    @Test func startWhileRunningEndsPreviousSession() throws {
        let service = try makeService()
        try service.start()
        clock.advance(minutes: 30)
        try service.start()

        let sessions = try allSessions()
        #expect(sessions.count == 2)
        #expect(sessions[0].end == clock.now)
        #expect(sessions[1].end == nil)
        #expect(service.current === sessions[1])
    }

    @Test func picksUpLatestRunningSessionAtLaunch() throws {
        let older = Session(start: clock.now, deviceName: "Test Mac")
        let newer = Session(start: clock.now + 60, deviceName: "Other Mac")
        context.insert(older)
        context.insert(newer)
        try context.save()

        let service = try makeService()
        #expect(service.current === newer)
    }

    @Test func startEndsEveryRunningSession() throws {
        context.insert(Session(start: clock.now, deviceName: "Test Mac"))
        context.insert(Session(start: clock.now + 60, deviceName: "Other Mac"))
        try context.save()
        clock.advance(minutes: 10)

        let service = try makeService()
        try service.start()

        let running = try allSessions().filter { $0.end == nil }
        #expect(running.count == 1)
        #expect(running.first === service.current)
    }

    @Test func stopEndsEveryRunningSession() throws {
        context.insert(Session(start: clock.now, deviceName: "Test Mac"))
        context.insert(Session(start: clock.now + 60, deviceName: "Other Mac"))
        try context.save()
        clock.advance(minutes: 10)

        let service = try makeService()
        try service.stop()

        #expect(try allSessions().allSatisfy { $0.end == clock.now })
    }

    @Test func changeCategoryWhileStoppedOnlySelectsIt() throws {
        let design = Category(name: "Design")
        context.insert(design)
        let service = try makeService()
        try service.changeCategory(to: design)

        #expect(service.selectedCategory === design)
        #expect(try allSessions().isEmpty)

        try service.start()
        #expect(service.current?.category === design)
    }

    @Test func changeCategoryWhileRunningMovesSession() throws {
        let design = Category(name: "Design")
        context.insert(design)
        let service = try makeService()
        let start = clock.now
        try service.start()
        try service.setNote("Logo sketches")
        clock.advance(minutes: 45)
        try service.changeCategory(to: design)

        let sessions = try allSessions()
        #expect(sessions.count == 1)
        #expect(sessions[0] === service.current)
        #expect(sessions[0].start == start)
        #expect(sessions[0].end == nil)
        #expect(sessions[0].category === design)
        #expect(sessions[0].note == "Logo sketches")
        #expect(service.selectedCategory === design)
    }

    @Test func changeCategoryWhileRunningIsSaved() throws {
        let design = Category(name: "Design")
        context.insert(design)
        let service = try makeService()
        try service.start()
        try service.changeCategory(to: design)

        #expect(!context.hasChanges)
    }

    @Test func changeToSameCategoryKeepsSession() throws {
        let design = Category(name: "Design")
        context.insert(design)
        let service = try makeService()
        try service.changeCategory(to: design)
        try service.start()
        clock.advance(minutes: 5)
        try service.changeCategory(to: design)

        #expect(try allSessions().count == 1)
        #expect(service.isRunning)
    }

    @Test func launchSelectsCategoryOfRunningSession() throws {
        let design = Category(name: "Design")
        context.insert(design)
        context.insert(Session(start: clock.now, category: design, deviceName: "Test Mac"))
        try context.save()

        let service = try makeService()
        #expect(service.selectedCategory === design)
    }

    @Test func setNoteUpdatesRunningSession() throws {
        let service = try makeService()
        try service.start()
        try service.setNote("Logo sketches")
        #expect(service.current?.note == "Logo sketches")

        try service.setNote("   ")
        #expect(service.current?.note == nil)
    }

    @Test func noteTypedWhileStoppedGoesOnNextSession() throws {
        let service = try makeService()
        try service.setNote("Logo sketches")
        #expect(service.nextNote == "Logo sketches")
        #expect(try allSessions().isEmpty)

        try service.start()
        #expect(service.current?.note == "Logo sketches")
        #expect(service.nextNote == nil)
    }

    @Test func blankNoteWhileStoppedClearsNextNote() throws {
        let service = try makeService()
        try service.setNote("Logo sketches")
        try service.setNote("  ")
        #expect(service.nextNote == nil)
    }

    @Test func changeCategoryWhileStoppedKeepsNextNote() throws {
        let design = Category(name: "Design")
        context.insert(design)
        let service = try makeService()
        try service.setNote("Logo sketches")
        try service.changeCategory(to: design)
        try service.start()

        #expect(service.current?.note == "Logo sketches")
        #expect(service.current?.category === design)
    }

    @Test func stopLeavesNoNextNote() throws {
        let service = try makeService()
        try service.setNote("Logo sketches")
        try service.start()
        try service.stop()
        try service.start()

        #expect(service.current?.note == nil)
    }
}
