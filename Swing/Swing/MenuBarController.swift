import AppKit
import KeyboardShortcuts
import SwiftUI

/// Controls displaying the menu bar icon, its panel, and handling the shortcut to toggle the panel
final class MenuBarController: NSObject {
    // The icon in the menu bar
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let panel: MenuBarPanel

    init(tracker: TemporaryTracker, openMainWindow: @escaping () -> Void) {
        var closePanel: () -> Void = {}
        panel = MenuBarPanel(content: PanelView(tracker: tracker, openMainWindow: {
            closePanel()
            openMainWindow()
        }))
        super.init()
        closePanel = { [weak self] in self?.panel.close() }

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Swing")
            button.target = self
            button.action = #selector(togglePanel)
        }

        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            self?.togglePanel()
        }
    }

    @objc private func togglePanel() {
        guard let button = statusItem.button, let itemWindow = button.window else { return }

        if panel.isVisible {
            panel.close()
        } else {
            // Lets the panel take keyboard input.
            NSApp.activate()
            let icon = itemWindow.convertToScreen(
                button.convert(button.cell?.imageRect(forBounds: button.bounds) ?? button.bounds, to: nil)
            )
            let anchor = NSRect(x: icon.minX, y: itemWindow.frame.minY, width: icon.width, height: 0)
            panel.show(below: anchor, on: itemWindow.screen, itemWindow: itemWindow)
        }
    }
}
