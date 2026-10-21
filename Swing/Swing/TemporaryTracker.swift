import Foundation
import Observation

/// In-memory stand-in for TrackingService until milestone 2.
@Observable
final class TemporaryTracker {
    /// When the running timer started, or `nil` when stopped.
    private(set) var start: Date?

    var isRunning: Bool { start != nil }

    func startOrStop() {
        start = isRunning ? nil : .now
    }
}
