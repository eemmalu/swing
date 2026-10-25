import AppKit
import os
import SwiftData
import SwingKit

/// Creates the menu bar item and main window, and handles app-wide events.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: "com.emmalu.Swing", category: "store")
    private let mainWindowController = MainWindowController()
    private var container: ModelContainer?
    private var menuBarController: MenuBarController?
    private var activityMonitor: ActivityMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController(state: makePanelState(), openMainWindow: { [mainWindowController] in
            mainWindowController.show()
        })
        activityMonitor = ActivityMonitor()
    }

    /// Opens the data store (or falls back to an in-memory one), creates TrackingService, then initializes PanelState
    private func makePanelState() -> PanelState {
        let deviceName = Host.current().localizedName ?? "Mac"
        do {
            let container = try SwingStore.makeContainer()
            self.container = container
            log.info("Store opened at \(container.configurations.first?.url.path ?? "?", privacy: .public)")
            let tracking = try TrackingService(context: container.mainContext, deviceName: deviceName)
            return PanelState(tracking: tracking, context: container.mainContext)
        } catch {
            log.error("Couldn't open the store: \(error, privacy: .public)")
        }
        do {
            let container = try SwingStore.makeContainer(inMemory: true)
            self.container = container
            let tracking = try TrackingService(context: container.mainContext, deviceName: deviceName)
            return PanelState(tracking: tracking, context: container.mainContext, storeUnavailable: true)
        } catch {
            fatalError("Couldn't open an in-memory store: \(error)")
        }
    }

    /// Shows the main window when the Dock icon is clicked with no window open.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { mainWindowController.show() }
        return true
    }

    /// Keeps the app running after the main window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
