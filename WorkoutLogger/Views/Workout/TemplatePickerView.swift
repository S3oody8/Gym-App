import SwiftData
import SwiftUI

/// Choose a template to start a workout from. Swipe to delete a template.
struct TemplatePickerView: View {
    let onPick: (WorkoutTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @State private var confirmDelete: WorkoutTemplate?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button {
                    onPick(template)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                        Text(exerciseList(template))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .tint(.primary)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        confirmDelete = template
                    }
                }
            }
            .overlay {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Save one from a workout's ⋯ menu.")
                    )
                }
            }
            .navigationTitle("Start from Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete template \(confirmDelete?.name ?? "")?",
                isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete Template", role: .destructive) {
                    if let template = confirmDelete {
                        do {
                            try WorkoutStore(context: context).deleteTemplate(template)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    confirmDelete = nil
                }
            } message: {
                Text("Past workouts are not affected.")
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func exerciseList(_ template: WorkoutTemplate) -> String {
        let names = template.orderedItems.compactMap { $0.exercise?.name }
        return names.isEmpty ? "No exercises" : names.joined(separator: " → ")
    }
}
