import AppKit
import SwiftUI

/// A menu-style box below the menu bar icon.
final class MenuBarPanel: NSPanel {
    private static let cornerRadius: CGFloat = 12
    private let hosting: NSView
    private var monitors: [Any] = []

    init(content: some View) {
        hosting = NSHostingView(rootView: content)
        super.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: true)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        let background = NSVisualEffectView()
        background.material = .menu
        background.state = .active
        background.maskImage = Self.roundedMask()

        hosting.frame = background.bounds
        hosting.autoresizingMask = [.width, .height]
        background.addSubview(hosting)
        contentView = background
    }

    /// Lets the panel take keyboard input.
    override var canBecomeKey: Bool { true }

    /// Closes the panel on Esc.
    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func close() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
        NotificationCenter.default.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        super.close()
    }

    /// Shows the panel below `icon` (in screen coordinates), kept on screen. Clicks in
    /// `itemWindow` are left to the menu bar item.
    func show(below icon: NSRect, on screen: NSScreen?, itemWindow: NSWindow) {
        setContentSize(hosting.fittingSize)
        let gap: CGFloat = 5
        var origin = NSPoint(x: icon.minX, y: icon.minY - gap - frame.height)
        if let visible = screen?.visibleFrame {
            origin.x = min(origin.x, visible.maxX - frame.width - gap)
        }
        setFrameOrigin(origin)
        makeKeyAndOrderFront(nil)
        invalidateShadow()
        closeOnClickOutside(except: itemWindow)
    }

    /// Resizes the panel to fit its content, keeping the top edge in place
    func fitContent() {
        let top = frame.maxY
        setContentSize(hosting.fittingSize)
        setFrameOrigin(NSPoint(x: frame.minX, y: top - frame.height))
        invalidateShadow()
    }

    /// Closes the panel on a click anywhere else or a switch to another app.
    private func closeOnClickOutside(except itemWindow: NSWindow) {
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: clicks, handler: { [weak self] _ in
            self?.close()
        }) {
            monitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: clicks, handler: { [weak self] event in
            if let self, event.window !== self, event.window !== itemWindow {
                self.close()
            }
            return event
        }) {
            monitors.append(monitor)
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(appResignedActive),
            name: NSApplication.didResignActiveNotification, object: nil
        )
    }

    @objc private func appResignedActive() {
        close()
    }

    /// A rounded-rectangle mask whose corners keep their radius at any size.
    private static func roundedMask() -> NSImage {
        let edge = cornerRadius * 2 + 1
        let mask = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            return true
        }
        mask.capInsets = NSEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        mask.resizingMode = .stretch
        return mask
    }
}
