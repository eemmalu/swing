import Foundation

/// The category's name, or "General" for `nil`
public func categoryName(_ category: Category?) -> String {
    category?.name ?? "General"
}

/// The category's color, or gray for `nil`
public func categoryColorHex(_ category: Category?) -> String {
    category?.colorHex ?? "#8E8E93"
}

public func rgbComponents(fromHex hex: String) -> (red: Double, green: Double, blue: Double)? {
    let digits = hex.hasPrefix("#") ? hex.dropFirst() : Substring(hex)
    guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
    return (
        red: Double((value >> 16) & 0xFF) / 255,
        green: Double((value >> 8) & 0xFF) / 255,
        blue: Double(value & 0xFF) / 255
    )
}
