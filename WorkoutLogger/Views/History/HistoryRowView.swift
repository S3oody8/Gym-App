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
        return [
            SessionMetrics.shortDate(session.startedAt),
            "\(sets) set\(sets == 1 ? "" : "s")",
            DurationFormatter.string(session.duration),
            SessionMetrics.loadText(session.load),
        ].joined(separator: " · ")
    }
}
