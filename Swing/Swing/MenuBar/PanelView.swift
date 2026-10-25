import SwiftData
import SwiftUI
import SwingKit

/// The menu bar panel's content.
struct PanelView: View {
    let state: PanelState
    let openMainWindow: () -> Void
    /// Called when the content changes height, so the panel can resize
    let contentResized: () -> Void
    @FocusState private var noteFocused: Bool
    @State private var addingCategory = false

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

            if addingCategory {
                NewCategoryField(done: finishAddingCategory)
            } else {
                CategoryMenu(
                    state: state,
                    addCategory: { addingCategory = true },
                    manageCategories: openMainWindow
                )
            }

            TextField("What are you working on?", text: $state.note)
                .textFieldStyle(.roundedBorder)
                .focused($noteFocused)
                .onSubmit { noteFocused = false }

            Button(state.tracking.isRunning ? "Stop" : "Start") {
                noteFocused = false
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
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { noteFocused = false }
        }
        .onChange(of: state.problem) { contentResized() }
        .onChange(of: addingCategory) { contentResized() }
    }

    /// Handler for when user finishes typing new category. `nil` means the user cancelled
    private func finishAddingCategory(_ name: String?) {
        addingCategory = false
        if let name { state.addCategory(named: name) }
    }
}

private struct CategoryMenu: View {
    let state: PanelState
    let addCategory: () -> Void
    let manageCategories: () -> Void

    var body: some View {
        let selected = state.tracking.selectedCategory

        Menu {
            Picker("Category", selection: Binding(
                get: { state.tracking.selectedCategory },
                set: { state.changeCategory(to: $0) }
            )) {
                item(nil)
                ForEach(state.categories) { item($0) }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Divider()
            Button("Add new…", action: addCategory)
            Button("Manage categories…", action: manageCategories)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(categoryName(selected))
                Rectangle()
                    .fill(Color(hex: categoryColorHex(selected)))
                    .frame(width: 9, height: 9)
            }
            .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Category: \(categoryName(selected))")
    }

    private func item(_ category: SwingKit.Category?) -> some View {
        Label {
            Text(categoryName(category))
        } icon: {
            Image(nsImage: colorSquareImage(hex: categoryColorHex(category)))
        }
        .tag(category)
    }
}

private struct NewCategoryField: View {
    let done: (String?) -> Void
    @State private var name = ""
    @State private var finished = false
    @FocusState private var focused: Bool

    var body: some View {
        TextField("New category name", text: $name)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .onAppear { focused = true }
            .onSubmit { finish(name) }
            .onExitCommand { finish(nil) }
            .onChange(of: focused) { if !focused { finish(name) } }
    }

    /// Send the result once
    private func finish(_ result: String?) {
        guard !finished else { return }
        finished = true
        done(result)
    }
}

/// The elapsed time, re-determined each second from `start` while running.
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
    PanelView(state: PanelState(tracking: tracking, context: container.mainContext), openMainWindow: {}, contentResized: {})
}
