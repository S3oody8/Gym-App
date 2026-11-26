import SwiftData
import SwiftUI

/// Exercise library: large title with a round +, search, a RECENT FIRST list (name and the
/// date it was last used), and archived exercises in their own section at the bottom.
/// Delete (no history) or archive (has history) by swiping.
struct ExercisesTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(PRCache.self) private var prCache
    @Query private var exercises: [Exercise]
    @State private var viewModel = ExerciseLibraryViewModel()
    @State private var editing: Exercise?
    @State private var isAdding = false
    @State private var pendingDelete: Exercise?
    @State private var path: [Exercise] = []

    var body: some View {
        NavigationStack(path: $path) {
            list
                .scrollContentBackground(.hidden)
                .background(Theme.background)
                .navigationDestination(for: Exercise.self) { exercise in
                    ExerciseProgressView(exercise: exercise)
                }
                .navigationTitle("Exercises")
                .searchable(text: $viewModel.searchText, prompt: "Search exercises")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isAdding = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundStyle(Theme.onAccent)
                                .frame(width: 32, height: 32)
                                .background(Theme.accent, in: Circle())
                        }
                        .accessibilityLabel("New exercise")
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
        let active = viewModel.visibleActive(exercises) { prCache.lastUsed($0.id) }
        let archived = viewModel.visibleArchived(exercises) { prCache.lastUsed($0.id) }
        if exercises.isEmpty {
            ContentUnavailableView {
                Label("No Exercises", systemImage: "dumbbell")
            } description: {
                Text("Add your first exercise with +.")
            }
        } else if active.isEmpty && archived.isEmpty && !viewModel.searchText.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                if !active.isEmpty {
                    Section {
                        ForEach(active) { exercise in
                            row(exercise)
                        }
                    } header: {
                        SectionLabel(viewModel.isSearching ? "Results" : "Recent first")
                    }
                    .listRowBackground(Theme.surface)
                }
                if !archived.isEmpty {
                    Section {
                        ForEach(archived) { exercise in
                            row(exercise)
                        }
                    } header: {
                        SectionLabel("Archived")
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func row(_ exercise: Exercise) -> some View {
        NavigationLink(value: exercise) {
            ExerciseRowView(exercise: exercise, lastUsed: prCache.lastUsed(exercise.id), query: viewModel.searchText)
        }
        .listRowSeparatorTint(Theme.hairline)
        .swipeActions(edge: .leading) {
            Button("Edit", systemImage: "pencil") { editing = exercise }
                .tint(Theme.raised)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if exercise.isArchived {
                Button("Unarchive", systemImage: "tray.and.arrow.up") {
                    viewModel.setArchived(false, for: exercise, in: context)
                }
                .tint(Theme.raised)
            } else if exercise.hasHistory {
                Button("Archive", systemImage: "archivebox") {
                    viewModel.setArchived(true, for: exercise, in: context)
                }
                .tint(.orange)
            } else {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    pendingDelete = exercise
                }
                .tint(Theme.destructive)
            }
        }
    }
}

#Preview {
    let container = try! ModelSchema.makeContainer(inMemory: true)
    ExercisesTabView()
        .modelContainer(container)
        .environment(PRCache.shared(for: container.mainContext))
}
