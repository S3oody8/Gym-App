import SwiftUI

/// One exercise in the active workout: its sets plus the add-set controls.
struct ExerciseCardSection: View {
    let entry: SessionExercise
    let viewModel: SessionEditorViewModel

    var body: some View {
        Section {
            ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                Button {
                    viewModel.openEdit(set, in: entry)
                } label: {
                    SetRowView(
                        number: index + 1,
                        values: set.values,
                        lastText: viewModel.lastText(for: entry, index: index)
                    )
                }
                .tint(.primary)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        viewModel.deleteSet(set, from: entry)
                    }
                }
            }
            QuickAddRow(
                canQuickAdd: viewModel.canQuickAdd(entry),
                onQuick: { viewModel.quickAdd(to: entry, minus: $0) },
                onAddSet: { viewModel.openAddSet(for: entry) }
            )
        } header: {
            HStack {
                Text(entry.exercise?.name ?? "Deleted exercise")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
                Spacer()
                Menu {
                    Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                        viewModel.removeEntry(entry)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Exercise options")
            }
        }
    }
}
