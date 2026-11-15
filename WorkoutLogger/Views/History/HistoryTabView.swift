import SwiftData
import SwiftUI

/// Finished sessions, newest first. Tap to edit; swipe to delete (asks first, with undo).
struct HistoryTabView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<WorkoutSession> { $0.finishedAt != nil },
        sort: \WorkoutSession.startedAt, order: .reverse
    )
    private var sessions: [WorkoutSession]
    @State private var viewModel = HistoryViewModel()
    @State private var path: [WorkoutSession] = []
    @State private var confirmDelete: WorkoutSession?
    /// Deleted once the detail screen has been popped, so no view reads a deleted session.
    @State private var deleteAfterPop: WorkoutSession?
    @State private var renaming: WorkoutSession?
    @State private var renameText = ""

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView("No Workouts Yet", systemImage: "clock.arrow.circlepath",
                                           description: Text("Finished workouts appear here."))
                } else {
                    List(sessions) { session in
                        NavigationLink(value: session) {
                            HistoryRowView(session: session)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                confirmDelete = session
                            }
                            Button("Rename", systemImage: "pencil") {
                                renameText = session.name
                                renaming = session
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session, context: context) {
                    deleteAfterPop = session
                    path.removeAll()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.deletedSnapshot != nil {
                    UndoToastView(message: "Workout deleted") { viewModel.undoDelete(in: context) }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: viewModel.deletedSnapshot)
            .confirmationDialog(
                "Delete this workout?",
                isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete Workout", role: .destructive) {
                    if let session = confirmDelete { viewModel.delete(session, in: context) }
                    confirmDelete = nil
                }
            } message: {
                Text("All its exercises and sets will be deleted. You can undo right after.")
            }
            .alert("Rename Workout", isPresented: Binding(
                get: { renaming != nil }, set: { if !$0 { renaming = nil } }
            )) {
                TextField("e.g. Anterior", text: $renameText)
                    .textInputAutocapitalization(.words)
                Button("Save") {
                    if let session = renaming {
                        do {
                            try WorkoutStore(context: context).rename(
                                session, to: renameText.trimmingCharacters(in: .whitespacesAndNewlines))
                        } catch {
                            viewModel.saveErrorMessage = error.localizedDescription
                        }
                    }
                    renaming = nil
                }
                Button("Cancel", role: .cancel) { renaming = nil }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { viewModel.saveErrorMessage != nil },
                set: { if !$0 { viewModel.saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.saveErrorMessage ?? "")
            }
            .onChange(of: path) { _, newPath in
                if newPath.isEmpty, let session = deleteAfterPop {
                    deleteAfterPop = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        viewModel.delete(session, in: context)
                    }
                }
            }
            .onAppear {
                if [.historyDetail, .historyDeleteFromDetail].contains(DebugScenario.current), path.isEmpty, let first = sessions.first {
                    path = [first]
                }
            }
        }
    }
}

#Preview {
    HistoryTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
