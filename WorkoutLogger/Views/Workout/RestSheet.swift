import SwiftUI

/// Rest sheet: a big ring with the time, "Alert at 3:00", −30 s / +30 s for this rest period
/// only, and Skip rest.
struct RestSheet: View {
    let timer: RestTimerStore
    let sessionID: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            if let rest = timer.visiblePeriod(for: sessionID) {
                TimelineView(.periodic(from: rest.start, by: 1)) { context in
                    ZStack {
                        RestRing(progress: RestTimerMath.progress(since: rest.start, alertSeconds: rest.alertSeconds,
                                                                  now: context.date),
                                 lineWidth: 10)
                        VStack(spacing: 4) {
                            Text("REST")
                                .font(.footnote.weight(.semibold))
                                .kerning(0.4)
                                .foregroundStyle(Theme.textMuted)
                            Text(RestTimerMath.format(RestTimerMath.elapsed(since: rest.start, now: context.date)))
                                .font(.system(size: 48, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Theme.accent)
                                .contentTransition(.numericText())
                        }
                    }
                    .frame(width: 200, height: 200)
                }
                .accessibilityElement(children: .combine)

                Text("Alert at \(RestTimerMath.format(TimeInterval(rest.alertSeconds)))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.text)

                HStack(spacing: 12) {
                    adjustButton("−30 s", delta: -30)
                    adjustButton("+30 s", delta: 30)
                }

                Button {
                    timer.skip()
                    dismiss()
                } label: {
                    Text("Skip rest")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity, minHeight: Theme.primaryButtonHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.border, lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Text("No rest running")
                    .foregroundStyle(Theme.textMuted)
                    .onAppear { dismiss() }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.surface)
    }

    private func adjustButton(_ title: String, delta: Int) -> some View {
        Button {
            timer.adjust(by: delta)
        } label: {
            Text(title)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: Theme.primaryButtonHeight)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(delta < 0 ? "Alert 30 seconds earlier" : "Alert 30 seconds later")
    }
}
