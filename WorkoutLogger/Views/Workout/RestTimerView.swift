import SwiftUI

/// Count-up rest stopwatch since the last logged set.
struct RestTimerView: View {
    let lastSetAt: Date?

    var body: some View {
        TimelineView(.periodic(from: lastSetAt ?? .now, by: 1)) { context in
            let elapsed = RestTimerMath.elapsed(since: lastSetAt, now: context.date)
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(RestTimerMath.format(elapsed))
                    .monospacedDigit()
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
            }
            .font(.subheadline)
            .foregroundStyle(lastSetAt == nil ? .secondary : .primary)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Rest \(RestTimerMath.format(elapsed))")
        }
    }
}
