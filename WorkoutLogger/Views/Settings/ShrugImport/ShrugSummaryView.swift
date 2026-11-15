import SwiftUI

/// Result of the Shrug import.
struct ShrugSummaryView: View {
    let result: ShrugImportResult

    var body: some View {
        List {
            Section {
                LabeledContent("Workouts imported", value: result.workoutsAdded.formatted())
                LabeledContent("Sets imported", value: result.setsAdded.formatted())
                LabeledContent("New exercises", value: result.exercisesCreated.formatted())
            } header: {
                Label("Import complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .textCase(nil)
            }
            Section("Skipped") {
                LabeledContent("Already imported", value: result.setsAlreadyImported.formatted())
                ForEach(result.skippedTimed.sorted { $0.key < $1.key }, id: \.key) { name, count in
                    LabeledContent("Timed (seconds): \(name)", value: count.formatted())
                }
                if result.unreadableLines > 0 {
                    LabeledContent("Unreadable rows", value: result.unreadableLines.formatted())
                }
            }
            Section {
                Text("PR badges are recalculated from the full history, so each exercise's first workout has none.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
