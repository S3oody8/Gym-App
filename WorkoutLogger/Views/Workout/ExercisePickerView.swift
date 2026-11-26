import SwiftData
import SwiftUI

/// Pick an exercise to add to the workout, or create one from the search text.
/// Archived exercises are hidden.
struct ExercisePickerView: View {
    let onPick: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(PRCache.self) private var prCache
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var creating = false
    @State private var createError: String?

    var body: some View {
        NavigationStack {
            let visible = ExerciseSearch.filter(exercises, query: searchText,
                                                name: \.name, isArchived: \.isArchived)
            let offered = ExerciseCreation.offeredName(for: searchText,
                                                       among: exercises.filter { !$0.isArchived }.map(\.name))
            List {
                ForEach(visible) { exercise in
                    Button {
                        pick(exercise)
                    } label: {
                        ExerciseRowView(exercise: exercise, lastUsed: prCache.lastUsed(exercise.id), query: searchText)
                    }
                    .tint(.primary)
                }
                if let offered {
                    CreateExerciseRow(name: offered, error: createError) { create(offered) }
                }
            }
            .overlay {
                if visible.isEmpty && offered == nil {
                    if searchText.isEmpty {
                        ContentUnavailableView("No Exercises", systemImage: "dumbbell",
                                               description: Text("Create one with New."))
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search exercises")
            .onChange(of: searchText) { createError = nil }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New", systemImage: "plus") { creating = true }
                }
            }
            .sheet(isPresented: $creating) {
                ExerciseEditorView(exercise: nil)
            }
        }
    }

    private func pick(_ exercise: Exercise) {
        onPick(exercise)
        dismiss()
    }

    private func create(_ name: String) {
        do {
            pick(try WorkoutStore(context: context).createExercise(named: name))
        } catch ExerciseDraft.ValidationError.duplicateName {
            createError = "An archived exercise has this name. Unarchive it in Exercises."
        } catch {
            createError = error.localizedDescription
        }
    }
}
