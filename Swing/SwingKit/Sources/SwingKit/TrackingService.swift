import Foundation
import Observation
import SwiftData

// Creates and manages sessions. Only one session runs at a time
@Observable
public final class TrackingService {
    // The running session, or `nil` when stopped
    public private(set) var current: Session?
    // `nil` means "General"
    public private(set) var selectedCategory: Category?
    public private(set) var nextNote: String?

    public var isRunning: Bool { current != nil }

    private let context: ModelContext
    private let deviceName: String
    // Function that returns the current date and time
    private let now: () -> Date

    public init(context: ModelContext, deviceName: String, now: @escaping () -> Date = { .now }) throws {
        self.context = context
        self.deviceName = deviceName
        self.now = now
        // Picks up the latest session still running in the store, if any
        current = try runningSessions().max { $0.start < $1.start }
        selectedCategory = current?.category
    }

    // Ends every running session, then starts a new one in the selected category
    public func start() throws {
        let time = now()
        try endRunningSessions(at: time)
        let session = Session(start: time, category: selectedCategory, note: nextNote, deviceName: deviceName)
        context.insert(session)
        current = session
        nextNote = nil
        try context.save()
    }

    public func stop() throws {
        try endRunningSessions(at: now())
        current = nil
        nextNote = nil
        try context.save()
    }

    // While running, ends the session and starts a new one with an empty note
    public func changeCategory(to category: Category?) throws {
        guard category !== selectedCategory else { return }
        selectedCategory = category
        if isRunning {
            try start()
        }
    }

    // Sets the running session's note, or the next note while stopped. Text that is empty or only spaces clears it
    public func setNote(_ note: String) throws {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        guard let current else {
            nextNote = note
            return
        }
        current.note = note
        try context.save()
    }

    private func runningSessions() throws -> [Session] {
        try context.fetch(FetchDescriptor<Session>(predicate: #Predicate { $0.end == nil }))
    }

    private func endRunningSessions(at time: Date) throws {
        for session in try runningSessions() {
            session.end = time
        }
    }
}
