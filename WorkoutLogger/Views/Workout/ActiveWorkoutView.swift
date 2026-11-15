import SwiftData
import SwiftUI
import UserNotifications

/// The live workout: exercise cards with sets, quick-add buttons, undo toast and bottom actions.
struct ActiveWorkoutView: View {
    @State private var viewModel: SessionEditorViewModel
    @State private var showPicker = false
    @State private var showSaveTemplate = false
    @State private var confirmFinish = false

    init(session: WorkoutSession, context: ModelContext) {
        _viewModel = State(initialValue: SessionEditorViewModel(session: session, context: context))
    }

    private var session: WorkoutSession { viewModel.session }

    var body: some View {
        List {
            Section {
                LabeledContent("Started", value: session.startedAt.formatted(date: .omitted, time: .shortened))
                LabeledContent("Sets", value: "\(viewModel.totalSets)")
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
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .toolbar {
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
        .onAppear(perform: openDebugPopupIfNeeded)
    }

    private var finishTitle: String {
        viewModel.totalSets == 0 ? "Discard empty workout?" : "Finish workout?"
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if let action = viewModel.undoAction {
                UndoToastView(message: action.message, onUndo: viewModel.undo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            RestTimerView(lastSetAt: viewModel.lastSetAt)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button {
                    showPicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    confirmFinish = true
                } label: {
                    Text("Finish")
                        .font(.headline)
                        .frame(minWidth: 80, minHeight: 50)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .animation(.snappy, value: viewModel.undoAction)
    }

    /// Debug-only scenarios used to screenshot and smoke-test flows (no-op in Release).
    private func openDebugPopupIfNeeded() {
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
