import SwiftData
import SwiftUI

/// A finished workout, read-only: name, "Mon 24/11 · 12:02 – 13:03", a Duration / Sets /
/// Volume card and each exercise as a compact table with PR marks. Edit opens the editor.
struct PastWorkoutView: View {
    let session: WorkoutSession
    let onDelete: () -> Void
    @Environment(\.modelContext) private var context
    @State private var editing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(SessionMetrics.title(name: session.name))
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Theme.text)
                    Text(HistoryFormat.detailLine(start: session.startedAt, end: session.finishedAt))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.textMuted)
                }
                statsCard
                ForEach(session.orderedEntries) { entry in
                    exerciseTable(entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
            }
        }
        .navigationDestination(isPresented: $editing) {
            SessionDetailView(session: session, context: context, onDelete: onDelete)
        }
    }

    private var statsCard: some View {
        GroupedCard(padding: 16) {
            HStack(alignment: .top) {
                stat("Duration", session.duration > 0 ? HistoryFormat.minutes(session.duration) : "—")
                stat("Sets", "\(session.allSets.count)")
                stat("Volume", HistoryFormat.volume(session.load))
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Theme.textMuted)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func exerciseTable(_ entry: SessionExercise) -> some View {
        let badges = entry.exercise.map { PRDetector.badges(for: ProgressQueries.prInputs(for: $0)) } ?? [:]
        return VStack(alignment: .leading, spacing: 8) {
            Text(entry.exercise?.name ?? "Deleted exercise")
                .font(.headline)
                .foregroundStyle(Theme.text)
            GroupedCard(padding: 12) {
                SetTableHeader()
                    .padding(.bottom, 6)
                ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                    Hairline()
                    SetTableRow(number: index + 1, values: set.values, badges: badges[set.id] ?? [])
                }
                if entry.sets.isEmpty {
                    Text("No sets")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSubtle)
                        .frame(minHeight: 38)
                }
            }
        }
    }
}
