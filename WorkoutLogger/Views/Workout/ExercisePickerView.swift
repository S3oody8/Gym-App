import SwiftData
import SwiftUI

/// Pick an exercise to add to the workout. Archived exercises are hidden.
struct ExercisePickerView: View {
    let onPick: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var creating = false

    var body: some View {
        NavigationStack {
            let visible = ExerciseSearch.filter(exercises, query: searchText,
                                                name: \.name, isArchived: \.isArchived)
            List(visible) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    ExerciseRowView(exercise: exercise, query: searchText)
                }
                .tint(.primary)
            }
            .overlay {
                if visible.isEmpty {
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
}
