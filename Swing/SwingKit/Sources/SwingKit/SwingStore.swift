import Foundation
import SwiftData

/// Opens the SwiftData store that holds user session data
public enum SwingStore {
    public static let appGroupID = "group.com.emmalu.swing"
    public static let schema = Schema([Category.self, Session.self])

    /// Opens the store in the App Group folder, or an empty in-memory one for tests and previews
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = if inMemory {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            ModelConfiguration(schema: schema, groupContainer: .identifier(appGroupID), cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
