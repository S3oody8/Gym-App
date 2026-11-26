import SwiftData
import SwiftUI
import UserNotifications

/// The live workout, full screen: ⌄ minimise and Finish on top, the name as a big title, the
/// exercise sections, the undo toast and the bottom actions.
struct ActiveWorkoutView: View {
    @State private var viewModel: SessionEditorViewModel
    @State private var showPicker = false
    @State private var showSaveTemplate = false
    @State private var confirmFinish = false
    @State private var askName = false
    @State private var finishName = ""
    @State private var showRest = false

    let onMinimise: () -> Void

    init(session: WorkoutSession, context: ModelContext, onMinimise: @escaping () -> Void) {
        _viewModel = State(initialValue: SessionEditorViewModel(session: session, context: context))
        self.onMinimise = onMinimise
    }

    private var session: WorkoutSession { viewModel.session }

    var body: some View {
        List {
            Section {
                header
                if session.entries.isEmpty {
                    AddExerciseCard { showPicker = true }
                        .padding(.top, 12)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            ForEach(session.orderedEntries) { entry in
                ExerciseCardSection(entry: entry, viewModel: viewModel)
            }
        }
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 34)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
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

    /// ⌄ minimise on the left; Finish (accent, grey while there are no sets) and ⋯ on the right.
    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onMinimise) {
                Image(systemName: "chevron.down")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: Theme.minTouch, height: Theme.minTouch)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Minimise workout")
            Spacer()
            Menu {
                Button("Save as Template", systemImage: "square.and.arrow.down") {
                    showSaveTemplate = true
                }
                .disabled(!viewModel.canSaveTemplate)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: Theme.minTouch, height: Theme.minTouch)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Workout options")
            Button(action: tapFinish) {
                Text("Finish")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(viewModel.totalSets > 0 ? Theme.onAccent : Theme.textMuted)
                    .padding(.horizontal, 16)
                    .frame(minHeight: Theme.pillHeight)
                    .background(viewModel.totalSets > 0 ? Theme.accent : Theme.raised, in: Capsule())
                    .frame(minHeight: Theme.minTouch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .background(Theme.background)
    }

    /// The name as a big title edited in place, the elapsed time on the right, "Started 12:45".
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                WorkoutNameField(viewModel: viewModel, font: .largeTitle.weight(.bold))
                let startedAt = session.startedAt
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text(HistoryFormat.minutes(context.date.timeIntervalSince(startedAt)))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.textMuted)
                        .fixedSize()
                }
            }
            Text("Started \(HistoryFormat.time(session.startedAt))")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
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
            RestDock(rest: viewModel.restPeriod, onRest: { showRest = true },
                     onAddExercise: { showPicker = true })
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Theme.background)
        .sheet(isPresented: $showRest) {
            RestSheet(timer: viewModel.restTimer, sessionID: session.id)
        }
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
