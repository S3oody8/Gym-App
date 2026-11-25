import SwiftUI

/// "Rest" in small grey, the big count-up time in the accent colour, "Alert at 3:00" on the right.
struct RestTimerLockScreenView: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RestTimerColors.muted)
                RestTimerText(state: state)
                    .font(.system(size: 44, weight: .semibold).monospacedDigit())
            }
            Spacer(minLength: 8)
            Text("Alert at \(RestTimerFormat.minutesSeconds(state.alertSeconds))")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(RestTimerColors.muted)
        }
    }
}
