import SwiftUI

/// One finished session: name as title, then "15/11 · 12 sets · 52 min · Load 4,820 kg".
struct HistoryRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(SessionMetrics.title(name: session.name))
                .font(.headline)
            Text(summary)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 1)
    }

    private var summary: String {
        let sets = session.allSets.count
        // Imported workouts have no per-set times, so a 0 duration is left out.
        let duration = session.duration > 0 ? DurationFormatter.string(session.duration) : nil
        return [
            SessionMetrics.shortDate(session.startedAt),
            "\(sets) set\(sets == 1 ? "" : "s")",
            duration,
            SessionMetrics.loadText(session.load),
        ].compactMap { $0 }.joined(separator: " · ")
    }
}
