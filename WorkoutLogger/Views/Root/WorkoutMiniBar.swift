import SwiftUI

/// Rounded card above the tab bar while the workout is minimised: a small rest ring, the
/// name, "38 min · Rest 1:42" and a ⌃ chevron. Tapping it re-opens the workout.
struct WorkoutMiniBar: View {
    let session: WorkoutSession
    let rest: RestPeriod?
    let onOpen: () -> Void

    var body: some View {
        // Plain values, so the per-second closures below never read the session.
        let rest = rest
        let startedAt = session.startedAt
        Button(action: onOpen) {
            HStack(spacing: 12) {
                TimelineView(.periodic(from: rest?.start ?? .now, by: 1)) { context in
                    RestRing(progress: rest.map { RestTimerMath.progress(since: $0.start, alertSeconds: $0.alertSeconds,
                                                                         now: context.date) } ?? 0)
                }
                .frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(SessionMetrics.title(name: session.name))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    TimelineView(.periodic(from: rest?.start ?? .now, by: 1)) { context in
                        Self.detail(startedAt: startedAt, rest: rest, now: context.date)
                            .font(.footnote.monospacedDigit())
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .accessibilityLabel("Workout in progress, \(SessionMetrics.title(name: session.name))")
        .accessibilityHint("Opens the workout")
    }

    private static func detail(startedAt: Date, rest: RestPeriod?, now: Date) -> Text {
        let elapsed = Text(HistoryFormat.minutes(now.timeIntervalSince(startedAt)))
            .foregroundStyle(Theme.textMuted)
        guard let rest else { return elapsed }
        let time = RestTimerMath.format(RestTimerMath.elapsed(since: rest.start, now: now))
        return elapsed + Text(" · Rest ").foregroundStyle(Theme.textMuted) + Text(time).foregroundStyle(Theme.accent)
    }
}
