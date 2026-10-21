import AppKit

/// Creates the menu bar item and main window, and handles app-wide events.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let tracker = TemporaryTracker()
    private let mainWindowController = MainWindowController()
    private var menuBarController: MenuBarController?
    private var activityMonitor: ActivityMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController(tracker: tracker, openMainWindow: { [mainWindowController] in
            mainWindowController.show()
        })
        activityMonitor = ActivityMonitor()
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
