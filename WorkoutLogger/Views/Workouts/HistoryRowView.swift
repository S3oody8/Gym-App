import SwiftUI

/// One finished workout as a card: the name, then "Mon 24/11 · 61 min · 20 sets · 6,140 kg"
/// and " · 1 PR" in the accent colour when the workout set any PR.
struct HistoryRowView: View {
    let session: WorkoutSession
    let prCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(SessionMetrics.title(name: session.name))
                .font(.headline)
                .foregroundStyle(Theme.text)
            summary
                .font(.subheadline.monospacedDigit())
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .contentShape(Rectangle())
    }

    private var summary: Text {
        let line = Text(HistoryFormat.rowLine(start: session.startedAt, duration: session.duration,
                                              sets: session.allSets.count, volume: session.load))
            .foregroundStyle(Theme.textMuted)
        guard let prs = HistoryFormat.prs(prCount) else { return line }
        return line + Text(" · ").foregroundStyle(Theme.textMuted) + Text(prs).foregroundStyle(Theme.accent)
    }
}
