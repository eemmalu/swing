import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Opens or closes the menu bar panel from any app.
    static let togglePanel = Self("togglePanel", initial: .init(.s, modifiers: [.control, .option]))
}
