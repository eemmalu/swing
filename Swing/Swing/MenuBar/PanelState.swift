import Foundation
import Observation
import os
import SwingKit

@Observable
final class PanelState {
    let tracking: TrackingService
    /// The note field's text. Saved a second after typing stops, on Start or Stop, and when the panel closes
    var note: String {
        didSet { if note != oldValue { scheduleNoteSave() } }
    }
    private var pendingNoteSave: Task<Void, Never>?
    /// The store couldn't be opened, so nothing tracked now is kept
    let storeUnavailable: Bool
    private(set) var saveFailed = false
    private let log = Logger(subsystem: "com.emmalu.Swing", category: "tracking")

    init(tracking: TrackingService, storeUnavailable: Bool = false) {
        self.tracking = tracking
        self.storeUnavailable = storeUnavailable
        note = tracking.current?.note ?? ""
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
        attemptSave { try tracking.stop() }
        showCurrentNote()
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

    private func attemptSave(_ action: () throws -> Void) {
        do {
            try action()
            saveFailed = false
        } catch {
            log.error("Save failed: \(error, privacy: .public)")
            saveFailed = true
        }
    }
}
