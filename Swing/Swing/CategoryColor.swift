import AppKit
import SwiftUI
import SwingKit

extension Color {
    init(hex: String) {
        self.init(nsColor: NSColor(hex: hex))
    }
}

extension NSColor {
    /// Gray if `hex` can't be read
    convenience init(hex: String) {
        let rgb = rgbComponents(fromHex: hex) ?? (red: 0.56, green: 0.56, blue: 0.58)
        self.init(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }
}

/// A small colored square for menu items, which draw SwiftUI shapes in a single color
func colorSquareImage(hex: String, size: CGFloat = 9) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        NSColor(hex: hex).setFill()
        rect.fill()
        return true
    }
    image.isTemplate = false
    return image
}
