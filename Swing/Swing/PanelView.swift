import SwiftUI
import SwingKit

/// The menu bar panel's content.
struct PanelView: View {
    let tracker: TemporaryTracker
    let openMainWindow: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TimerText(start: tracker.start)

            Button(tracker.isRunning ? "Stop" : "Start") {
                tracker.startOrStop()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)

            Divider()

            Button("Open Swing", action: openMainWindow)
                .buttonStyle(.link)
        }
        .padding()
        .frame(width: 260)
    }
}

/// The elapsed time, muted while stopped and redrawn each second from `start` while running.
private struct TimerText: View {
    let start: Date?

    var body: some View {
        if let start {
            TimelineView(.periodic(from: start, by: 1)) { context in
                label(elapsedTime(start: start, end: nil, now: context.date))
            }
        } else {
            label(0)
                .foregroundStyle(.secondary)
        }
    }

    private func label(_ seconds: TimeInterval) -> some View {
        Text(formattedElapsedTime(seconds))
            .font(.largeTitle.monospacedDigit())
    }
}

#Preview {
    PanelView(tracker: TemporaryTracker(), openMainWindow: {})
}
