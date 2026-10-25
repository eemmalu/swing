import AppKit
import KeyboardShortcuts
import SwiftUI

/// Controls displaying the menu bar icon, its panel, and handling the shortcut to toggle the panel
final class MenuBarController: NSObject {
    // The icon in the menu bar
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let state: PanelState
    private let openMainWindow: () -> Void
    private lazy var panel: MenuBarPanel = MenuBarPanel(content: PanelView(
        state: state,
        openMainWindow: { [weak self] in
            self?.panel.close()
            self?.openMainWindow()
        },
        contentResized: { [weak self] in
            // Waits for the new content to be laid out
            DispatchQueue.main.async { self?.panel.fitContent() }
        }
    ))

    init(state: PanelState, openMainWindow: @escaping () -> Void) {
        self.state = state
        self.openMainWindow = openMainWindow
        super.init()

        // When the panel is about to close, save the current note
        NotificationCenter.default.addObserver(
            self, selector: #selector(panelWillClose),
            name: NSWindow.willCloseNotification, object: panel
        )

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Swing")
            button.target = self
            button.action = #selector(togglePanel)
        }

        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            self?.togglePanel()
        }
    }

    @objc private func panelWillClose() {
        state.saveNote()
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
            state.refreshCategories()
            panel.show(below: anchor, on: itemWindow.screen, itemWindow: itemWindow)
        }
    }
}
