import SwiftUI

/// Placeholder content for the main window, with the Quit button.
struct MainWindowView: View {
    var body: some View {
        VStack {
            ContentUnavailableView(
                "History goes here",
                systemImage: "calendar",
                description: Text("Your sessions, stats and settings will live in this window.")
            )

            HStack {
                Spacer()
                Button("Quit Swing") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    MainWindowView()
}
