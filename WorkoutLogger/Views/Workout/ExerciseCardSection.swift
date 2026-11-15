import SwiftUI

/// One exercise in a session: accent-coloured header with "+ Add Set", slim set rows,
/// and the −1/−2/−3 chips under the last set.
struct ExerciseCardSection: View {
    let entry: SessionExercise
    let viewModel: SessionEditorViewModel

    private static let rowInsets = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 4)

    var body: some View {
        let badges = viewModel.prBadges(for: entry)
        Section {
            ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                SetRowView(
                    number: index + 1,
                    values: set.values,
                    badges: badges[set.id] ?? [],
                    lastText: viewModel.lastText(for: entry, index: index),
                    onEdit: { viewModel.openEdit(set, in: entry) },
                    onDelete: { viewModel.deleteSet(set, from: entry) }
                )
                .listRowInsets(Self.rowInsets)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        viewModel.deleteSet(set, from: entry)
                    }
                }
            }
            if viewModel.canQuickAdd(entry) {
                QuickAddRow { viewModel.quickAdd(to: entry, minus: $0) }
                    .listRowInsets(Self.rowInsets)
            }
        } header: {
            HStack(spacing: 8) {
                Text(entry.exercise?.name ?? "Deleted exercise")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                    .textCase(nil)
                    .lineLimit(2)
                Spacer(minLength: 4)
                Button {
                    viewModel.openAddSet(for: entry)
                } label: {
                    Text("+ Add Set")
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                }
                .buttonStyle(.borderless)
                Menu {
                    Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                        viewModel.removeEntry(entry)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(minWidth: 32, minHeight: 32)
                }
                .accessibilityLabel("Exercise options")
            }
        }
    }
}
