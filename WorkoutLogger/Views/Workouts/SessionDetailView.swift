import SwiftData
import SwiftUI

/// Edit a finished session: its date/time, exercises and every set.
struct SessionDetailView: View {
    @State private var viewModel: SessionEditorViewModel
    @State private var showPicker = false
    @State private var showSaveTemplate = false
    @State private var confirmDelete = false
    let onDelete: () -> Void

    init(session: WorkoutSession, context: ModelContext, onDelete: @escaping () -> Void) {
        _viewModel = State(initialValue: SessionEditorViewModel(session: session, context: context))
        self.onDelete = onDelete
    }

    private var session: WorkoutSession { viewModel.session }

    var body: some View {
        List {
            Section {
                WorkoutNameField(viewModel: viewModel)
                DatePicker(
                    "Started",
                    selection: Binding(get: { session.startedAt }, set: { viewModel.moveStart(to: $0) }),
                    in: ...Date.now
                )
                Text([
                    "\(viewModel.totalSets) sets",
                    DurationFormatter.string(session.duration),
                    SessionMetrics.loadText(session.load),
                ].joined(separator: " · "))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            } footer: {
                Text("Changing the start moves every set by the same amount. Duration runs from the first set to the last.")
            }
            ForEach(session.orderedEntries) { entry in
                ExerciseCardSection(entry: entry, viewModel: viewModel)
            }
        }
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 34)
        .navigationTitle(SessionMetrics.detailTitle(name: session.name, date: session.startedAt))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Save as Template", systemImage: "square.and.arrow.down") {
                        showSaveTemplate = true
                    }
                    .disabled(!viewModel.canSaveTemplate)
                    Button("Delete Workout", systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Workout options")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if let action = viewModel.undoAction {
                    UndoToastView(message: action.message, onUndo: viewModel.undo)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Button {
                    showPicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
            .animation(.snappy, value: viewModel.undoAction)
        }
        .modifier(SessionEditingModifier(viewModel: viewModel, showPicker: $showPicker,
                                         showSaveTemplate: $showSaveTemplate))
        .task {
            // Debug-only smoke test of deleting from this screen (no-op in Release).
            guard DebugScenario.current == .historyDeleteFromDetail else { return }
            try? await Task.sleep(for: .seconds(1.5))
            onDelete()
        }
        .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive, action: onDelete)
        } message: {
            Text("All its exercises and sets will be deleted. You can undo right after.")
        }
    }
}
