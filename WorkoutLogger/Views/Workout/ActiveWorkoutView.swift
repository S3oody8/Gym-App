import SwiftData
import SwiftUI
import UserNotifications

/// The live workout: name, exercise sections with slim set rows, undo toast, rest timer and
/// compact bottom actions.
struct ActiveWorkoutView: View {
    @State private var viewModel: SessionEditorViewModel
    @State private var showPicker = false
    @State private var showSaveTemplate = false
    @State private var confirmFinish = false
    @State private var askName = false
    @State private var finishName = ""

    let onMinimise: () -> Void

    init(session: WorkoutSession, context: ModelContext, onMinimise: @escaping () -> Void) {
        _viewModel = State(initialValue: SessionEditorViewModel(session: session, context: context))
        self.onMinimise = onMinimise
    }

    private var session: WorkoutSession { viewModel.session }

    var body: some View {
        List {
            Section {
                WorkoutNameField(viewModel: viewModel)
                Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened)) · \(viewModel.totalSets) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if session.entries.isEmpty {
                Section {
                    Text("Tap Add Exercise to begin.")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(session.orderedEntries) { entry in
                ExerciseCardSection(entry: entry, viewModel: viewModel)
            }
        }
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 34)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Minimise", systemImage: "chevron.down", action: onMinimise)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Save as Template", systemImage: "square.and.arrow.down") {
                        showSaveTemplate = true
                    }
                    .disabled(!viewModel.canSaveTemplate)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Workout options")
            }
        }
        .modifier(SessionEditingModifier(viewModel: viewModel, showPicker: $showPicker,
                                         showSaveTemplate: $showSaveTemplate))
        .confirmationDialog(finishTitle, isPresented: $confirmFinish, titleVisibility: .visible) {
            if viewModel.totalSets == 0 {
                Button("Discard Workout", role: .destructive) { viewModel.discard() }
            } else {
                Button("Finish Workout") { viewModel.finish() }
            }
        } message: {
            if viewModel.totalSets == 0 {
                Text("No sets were logged, so the workout won't be saved.")
            }
        }
        .alert("Name this workout", isPresented: $askName) {
            TextField("e.g. Anterior", text: $finishName)
                .textInputAutocapitalization(.words)
            Button("Save & Finish") { viewModel.finish(naming: finishName) }
                .disabled(finishName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("Skip") { viewModel.finish() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: runDebugScenario)
    }

    private var finishTitle: String {
        viewModel.totalSets == 0 ? "Discard empty workout?" : "Finish workout?"
    }

    private func tapFinish() {
        if viewModel.totalSets > 0 && viewModel.needsNameBeforeFinish {
            finishName = ""
            askName = true
        } else {
            confirmFinish = true
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if let action = viewModel.undoAction {
                UndoToastView(message: action.message, onUndo: viewModel.undo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            HStack(spacing: 10) {
                RestTimerView(lastSetAt: viewModel.lastSetAt)
                Spacer(minLength: 8)
                Button {
                    showPicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                Button("Finish", action: tapFinish)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
            }
            .controlSize(.regular)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .animation(.snappy, value: viewModel.undoAction)
    }

    /// Debug-only scenarios used to screenshot and smoke-test flows (no-op in Release).
    private func runDebugScenario() {
        switch DebugScenario.current {
        case .workoutPopup:
            if let entry = session.orderedEntries.first { viewModel.openAddSet(for: entry) }
        case .workoutDiscard:
            Task {
                try? await Task.sleep(for: .seconds(1))
                viewModel.discard()
            }
        case .workoutRemoveUndo:
            Task {
                try? await Task.sleep(for: .seconds(1))
                if let entry = session.orderedEntries.first { viewModel.removeEntry(entry) }
                try? await Task.sleep(for: .seconds(1))
                viewModel.undo()
            }
        case .restAlert:
            Task {
                let center = UNUserNotificationCenter.current()
                _ = try? await center.requestAuthorization(options: [.alert, .sound, .provisional])
                if let entry = session.orderedEntries.first { viewModel.quickAdd(to: entry, minus: 1) }
                try? await Task.sleep(for: .seconds(1))
                let pending = await center.pendingNotificationRequests().map {
                    "\($0.identifier) in \(Int(($0.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval ?? -1))s"
                }
                print("DEBUG pending: \(pending)")
                try? await Task.sleep(for: .seconds(35))
                let delivered = await center.deliveredNotifications().map {
                    "\($0.request.identifier): \($0.request.content.title) / \($0.request.content.body)"
                }
                print("DEBUG delivered: \(delivered)")
            }
        default:
            break
        }
    }
}
