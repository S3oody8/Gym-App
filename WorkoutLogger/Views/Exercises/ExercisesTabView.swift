import SwiftData
import SwiftUI

/// Exercise library: search, add, edit, delete (no history) or archive (has history).
struct ExercisesTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var exercises: [Exercise]
    @State private var viewModel = ExerciseLibraryViewModel()
    @State private var editing: Exercise?
    @State private var isAdding = false
    @State private var pendingDelete: Exercise?
    @State private var path: [Exercise] = []

    var body: some View {
        NavigationStack(path: $path) {
            list
                .navigationDestination(for: Exercise.self) { exercise in
                    ExerciseProgressView(exercise: exercise)
                }
                .navigationTitle("Exercises")
                .searchable(text: $viewModel.searchText, prompt: "Search exercises")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Toggle(isOn: $viewModel.showArchived) {
                            Label("Show Archived", systemImage: "archivebox")
                        }
                        .toggleStyle(.button)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add Exercise", systemImage: "plus") { isAdding = true }
                    }
                }
                .sheet(isPresented: $isAdding) {
                    ExerciseEditorView(exercise: nil)
                }
                .sheet(item: $editing) { exercise in
                    ExerciseEditorView(exercise: exercise)
                }
                .confirmationDialog(
                    "Delete \(pendingDelete?.name ?? "exercise")?",
                    isPresented: Binding(
                        get: { pendingDelete != nil },
                        set: { if !$0 { pendingDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        if let exercise = pendingDelete {
                            viewModel.delete(exercise, in: context)
                        }
                        pendingDelete = nil
                    }
                } message: {
                    Text("This exercise has no history. It will also be removed from any templates. This can't be undone.")
                }
                .alert("Couldn't save", isPresented: Binding(
                    get: { viewModel.saveErrorMessage != nil },
                    set: { if !$0 { viewModel.saveErrorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.saveErrorMessage ?? "")
                }
                .onAppear {
                    if DebugScenario.current == .exerciseEditor, editing == nil {
                        editing = exercises.first { $0.hasHistory && !$0.isArchived }
                    }
                    if DebugScenario.current == .exerciseProgress, path.isEmpty,
                       let bench = exercises.first(where: { $0.name == "Bench Press" }) {
                        path = [bench]
                    }
                }
        }
    }

    @ViewBuilder
    private var list: some View {
        let active = viewModel.visibleActive(exercises)
        let archived = viewModel.visibleArchived(exercises)
        if exercises.isEmpty {
            ContentUnavailableView {
                Label("No Exercises", systemImage: "dumbbell")
            } description: {
                Text("Add your first exercise.")
            } actions: {
                Button("Add Exercise") { isAdding = true }
                    .buttonStyle(.borderedProminent)
            }
        } else if active.isEmpty && archived.isEmpty && !viewModel.searchText.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else if active.isEmpty && archived.isEmpty {
            ContentUnavailableView {
                Label("All Exercises Archived", systemImage: "archivebox")
            } actions: {
                Button("Show Archived") { viewModel.showArchived = true }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                Section {
                    ForEach(active) { exercise in
                        row(exercise)
                    }
                }
                if !archived.isEmpty {
                    Section("Archived") {
                        ForEach(archived) { exercise in
                            row(exercise)
                        }
                    }
                }
            }
        }
    }

    private func row(_ exercise: Exercise) -> some View {
        NavigationLink(value: exercise) {
            ExerciseRowView(exercise: exercise)
        }
        .swipeActions(edge: .leading) {
            Button("Edit", systemImage: "pencil") { editing = exercise }
                .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if exercise.isArchived {
                Button("Unarchive", systemImage: "tray.and.arrow.up") {
                    viewModel.setArchived(false, for: exercise, in: context)
                }
                .tint(.blue)
            } else if exercise.hasHistory {
                Button("Archive", systemImage: "archivebox") {
                    viewModel.setArchived(true, for: exercise, in: context)
                }
                .tint(.orange)
            } else {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    pendingDelete = exercise
                }
            }
        }
    }
}

#Preview {
    ExercisesTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
