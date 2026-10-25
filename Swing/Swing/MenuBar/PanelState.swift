import Foundation
import Observation
import os
import SwiftData
import SwingKit

@Observable
final class PanelState {
    let tracking: TrackingService
    private let context: ModelContext
    private(set) var categories: [SwingKit.Category] = []
    /// The note field's text. Saved a second after typing stops, on Start or Stop, and when the panel closes
    var note: String {
        didSet { if note != oldValue { scheduleNoteSave() } }
    }
    private var pendingNoteSave: Task<Void, Never>?
    /// The store couldn't be opened, so nothing tracked now is kept
    let storeUnavailable: Bool
    private(set) var saveFailed = false
    private let log = Logger(subsystem: "com.emmalu.Swing", category: "tracking")

    init(tracking: TrackingService, context: ModelContext, storeUnavailable: Bool = false) {
        self.tracking = tracking
        self.context = context
        self.storeUnavailable = storeUnavailable
        note = tracking.current?.note ?? ""
        refreshCategories()
    }

    var problem: String? {
        if storeUnavailable { return "Can't save your session. Try restarting Swing." }
        if saveFailed { return "Couldn't save. Your time may not be kept." }
        return nil
    }

    func start() {
        saveNote()
        attemptSave { try tracking.start() }
        showCurrentNote()
    }

    func stop() {
        saveNote()
        let session = tracking.current
        if attemptSave({ try tracking.stop() }), let session {
            logStopped(session)
        }
        showCurrentNote()
    }

    private func logStopped(_ session: Session) {
        let end = session.end ?? .now
        let length = Duration.seconds(end.timeIntervalSince(session.start)).formatted(.time(pattern: .hourMinuteSecond))
        log.notice("""
            Stopped session \(session.id.uuidString, privacy: .public)
              category: \(categoryName(session.category), privacy: .public)
              start: \(session.start.formatted(date: .abbreviated, time: .standard), privacy: .public)
              end: \(end.formatted(date: .abbreviated, time: .standard), privacy: .public)
              length: \(length, privacy: .public)
              note: \(session.note ?? "(none)", privacy: .public)
              device: \(session.deviceName, privacy: .public)
            """)
    }

    func changeCategory(to category: SwingKit.Category?) {
        attemptSave { try tracking.changeCategory(to: category) }
    }

    func addCategory(named name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var category: SwingKit.Category?
        guard attemptSave({ category = try SwingKit.addCategory(named: name, in: context) }) else { return }
        refreshCategories()
        changeCategory(to: category)
    }

    func refreshCategories() {
        do {
            categories = try unarchivedCategories(in: context)
        } catch {
            log.error("Couldn't load categories: \(error, privacy: .public)")
        }
    }

    func saveNote() {
        pendingNoteSave?.cancel()
        attemptSave { try tracking.setNote(note) }
    }

    /// Shows the running session's note in the field, without saving it again
    private func showCurrentNote() {
        note = tracking.current?.note ?? ""
        pendingNoteSave?.cancel()
    }

    private func scheduleNoteSave() {
        pendingNoteSave?.cancel()
        pendingNoteSave = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.saveNote()
        }
    }

    @discardableResult
    private func attemptSave(_ action: () throws -> Void) -> Bool {
        do {
            try action()
            saveFailed = false
            return true
        } catch {
            log.error("Save failed: \(error, privacy: .public)")
            saveFailed = true
            return false
        }
    }
}
