import SwiftUI

/// The count-up rest time, ticking without the app.
struct RestTimerText: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        Text(timerInterval: state.start...state.start.addingTimeInterval(12 * 3600), countsDown: false)
            .monospacedDigit()
            .foregroundStyle(RestTimerColors.accent)
            .multilineTextAlignment(.leading)
    }
}
