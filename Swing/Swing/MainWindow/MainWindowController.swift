import AppKit
import SwiftUI

/// The main window. The app shows a Dock icon only while it's open.
final class MainWindowController: NSObject, NSWindowDelegate {
    private lazy var window: NSWindow = {
        let window = NSWindow(contentViewController: NSHostingController(rootView: MainWindowView()))
        window.title = "Swing"
        window.setContentSize(NSSize(width: 480, height: 360))
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }()

    func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
