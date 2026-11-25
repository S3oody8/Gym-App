import SwiftUI

/// Bottom dock of the live workout: the rest box (ring, REST, time) on the left and an
/// outlined Add exercise button on the right, as two equal halves.
struct RestDock: View {
    let rest: RestPeriod?
    let onRest: () -> Void
    let onAddExercise: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onRest) {
                TimelineView(.periodic(from: rest?.start ?? .now, by: 1)) { context in
                    HStack(spacing: 10) {
                        RestRing(progress: rest.map {
                            RestTimerMath.progress(since: $0.start, alertSeconds: $0.alertSeconds, now: context.date)
                        } ?? 0)
                        .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("REST")
                                .font(.caption2.weight(.semibold))
                                .kerning(0.4)
                                .foregroundStyle(Theme.textMuted)
                            Text(rest.map { RestTimerMath.format(RestTimerMath.elapsed(since: $0.start, now: context.date)) } ?? "—")
                                .font(.title3.weight(.semibold).monospacedDigit())
                                .foregroundStyle(rest == nil ? Theme.textFaint : Theme.accent)
                                .contentTransition(.numericText())
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(rest.map {
                        "Rest \(RestTimerMath.format(RestTimerMath.elapsed(since: $0.start, now: context.date)))"
                    } ?? "Rest timer, starts with the next set")
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(rest == nil)
            .accessibilityHint("Opens the rest timer")

            Button(action: onAddExercise) {
                Label("Add exercise", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
