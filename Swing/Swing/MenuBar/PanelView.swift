import SwiftData
import SwiftUI
import SwingKit

/// The menu bar panel's content.
struct PanelView: View {
    let state: PanelState
    let openMainWindow: () -> Void
    /// Called when the content changes height, so the panel can resize
    let contentResized: () -> Void

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 12) {
            TimerText(start: state.tracking.current?.start)

            if let problem = state.problem {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            TextField("What are you working on?", text: $state.note)
                .textFieldStyle(.roundedBorder)

            Button(state.tracking.isRunning ? "Stop" : "Start") {
                if state.tracking.isRunning { state.stop() } else { state.start() }
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)

            Divider()

            Button("Open Swing", action: openMainWindow)
                .buttonStyle(.link)
        }
        .padding()
        .frame(width: 260)
        .onChange(of: state.problem) { contentResized() }
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
    let container = try! SwingStore.makeContainer(inMemory: true)
    let tracking = try! TrackingService(context: container.mainContext, deviceName: "Preview Mac")
    PanelView(state: PanelState(tracking: tracking), openMainWindow: {}, contentResized: {})
}
