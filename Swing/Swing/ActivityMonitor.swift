import AppKit
import CoreGraphics
import os

/// Watches for time without input and for the Mac sleeping and waking. For now it only logs them.
final class ActivityMonitor: NSObject {
    private static let anyInput = CGEventType(rawValue: ~0)!
    private let log = Logger(subsystem: "com.emmalu.Swing", category: "activity")
    private var sleptAt: Date?
    private var timer: Timer?

    /// Seconds since the last keyboard, mouse or trackpad input.
    static var idleSeconds: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }

    /// Starts watching. Lives as long as the app.
    override init() {
        super.init()
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        center.addObserver(self, selector: #selector(screensDidSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(screensDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(logIdle), userInfo: nil, repeats: true)
        logIdle()
    }

    /// Logs the current idle time. Runs every 30 seconds.
    @objc private func logIdle() {
        log.notice("Idle for \(Self.idleSeconds, format: .fixed(precision: 0)) s")
    }

    /// Notes when the Mac starts going to sleep.
    @objc private func willSleep() {
        sleptAt = .now
        log.notice("Mac going to sleep")
    }

    /// Logs how long the Mac slept, and the idle time on waking.
    @objc private func didWake() {
        let asleep = sleptAt.map { Date.now.timeIntervalSince($0) } ?? -1
        sleptAt = nil
        log.notice("Mac woke after \(asleep, format: .fixed(precision: 0)) s asleep; idle for \(Self.idleSeconds, format: .fixed(precision: 0)) s")
    }

    /// Logs when the displays turn off, for example after the display sleep timer.
    @objc private func screensDidSleep() {
        log.notice("Screens went to sleep")
    }

    /// Logs when the displays turn back on.
    @objc private func screensDidWake() {
        log.notice("Screens woke; idle for \(Self.idleSeconds, format: .fixed(precision: 0)) s")
    }
}
