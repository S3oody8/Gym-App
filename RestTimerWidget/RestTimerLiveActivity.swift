import ActivityKit
import SwiftUI
import WidgetKit

/// Rest timer on the lock screen and in the Dynamic Island. The time counts up on its own
/// (`Text(timerInterval:countsDown: false)`), so the app doesn't need to run.
struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            RestTimerLockScreenView(state: context.state)
                .padding(16)
                .activityBackgroundTint(RestTimerColors.background)
                .activitySystemActionForegroundColor(RestTimerColors.text)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    RestTimerLockScreenView(state: context.state)
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(RestTimerColors.accent)
            } compactTrailing: {
                RestTimerText(state: context.state)
                    .frame(maxWidth: 52)
            } minimal: {
                RestTimerText(state: context.state)
                    .frame(maxWidth: 44)
            }
            .keylineTint(RestTimerColors.accent)
        }
    }
}
