import SwiftUI

/// One exercise in a session: the name (accent for the current exercise), "+ Set" on the
/// right, a SET · KG · REPS · NOTE header, one 38 pt row per set, and the "Repeat" quick
/// buttons under the current exercise only. Tap a set to edit it; swipe left to delete.
struct ExerciseCardSection: View {
    let entry: SessionExercise
    let viewModel: SessionEditorViewModel

    private static let rowInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

    var body: some View {
        let badges = viewModel.prBadges(for: entry)
        let isCurrent = viewModel.isCurrent(entry)
        Section {
            if !entry.sets.isEmpty {
                SetTableHeader()
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                VStack(spacing: 0) {
                    SetTableRow(number: index + 1, values: set.values, badges: badges[set.id] ?? [])
                    Hairline()
                }
                .onTapGesture { viewModel.openEdit(set, in: entry) }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Edits this set")
                .listRowInsets(Self.rowInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        viewModel.deleteSet(set, from: entry)
                    }
                    .tint(Theme.destructive)
                }
            }
            if isCurrent && viewModel.canQuickAdd(entry) && !viewModel.quickButtons.isEmpty {
                QuickAddRow(values: viewModel.quickButtons) { viewModel.quickAdd(to: entry, minus: $0) }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        } header: {
            HStack(spacing: 8) {
                Text(entry.exercise?.name ?? "Deleted exercise")
                    .font(.headline)
                    .foregroundStyle(isCurrent ? Theme.accent : Theme.text)
                    .textCase(nil)
                    .lineLimit(2)
                    .contextMenu {
                        Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                            viewModel.removeEntry(entry)
                        }
                    }
                Spacer(minLength: 4)
                Button {
                    viewModel.openAddSet(for: entry)
                } label: {
                    Text("+ Set")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .textCase(nil)
                        .frame(minWidth: Theme.minTouch, minHeight: Theme.minTouch, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add set to \(entry.exercise?.name ?? "exercise")")
            }
            .padding(.top, 8)
        }
    }
}
