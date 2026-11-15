import SwiftUI

/// One finished session in the History list.
struct HistoryRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startedAt.formatted(.dateTime.weekday(.wide).day().month().year()))
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !exerciseNames.isEmpty {
                Text(exerciseNames)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private var summary: String {
        let sets = session.allSets.count
        return [
            session.startedAt.formatted(date: .omitted, time: .shortened),
            "\(sets) set\(sets == 1 ? "" : "s")",
            DurationFormatter.string(session.duration),
        ].joined(separator: " · ")
    }

    private var exerciseNames: String {
        session.orderedEntries.map { $0.exercise?.name ?? "Deleted exercise" }.joined(separator: ", ")
    }
}
