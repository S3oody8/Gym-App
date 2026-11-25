import Foundation
#if LIVEACTIVITY
import ActivityKit
#endif

/// The rest-timer Live Activity on the lock screen and in the Dynamic Island. Only compiled in
/// with the `LIVEACTIVITY` flag; otherwise (or with Settings → Lock screen timer off, or when
/// Live Activities aren't available) it does nothing and the "Rest over" notification is the
/// fallback. That notification fires in every case.
@MainActor
final class RestActivityController: RestActivityControlling {
    static let shared = RestActivityController()

    static var isCompiledIn: Bool {
        #if LIVEACTIVITY
        true
        #else
        false
        #endif
    }

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKeys.liveActivityEnabled) == nil
            ? SettingsKeys.defaultLiveActivityEnabled
            : UserDefaults.standard.bool(forKey: SettingsKeys.liveActivityEnabled)
    }

    #if LIVEACTIVITY
    /// Activity calls run one after another so an update never lands after an end.
    private var queue: Task<Void, Never>?

    private func enqueue(_ work: @escaping @Sendable () async -> Void) {
        let previous = queue
        queue = Task {
            await previous?.value
            await work()
        }
    }
    #endif

    func show(_ period: RestPeriod) {
        #if LIVEACTIVITY
        guard Self.isEnabled, ActivityAuthorizationInfo().areActivitiesEnabled else { return end() }
        let state = RestTimerAttributes.ContentState(start: period.start, alertSeconds: period.alertSeconds)
        let sessionID = period.sessionID
        enqueue { await Self.startOrUpdate(sessionID: sessionID, state: state) }
        #endif
    }

    func end() {
        #if LIVEACTIVITY
        enqueue { await Self.endAll() }
        #endif
    }

    #if LIVEACTIVITY
    private nonisolated static func startOrUpdate(sessionID: UUID, state: RestTimerAttributes.ContentState) async {
        let content = ActivityContent(state: state, staleDate: nil)
        var updated = false
        for activity in Activity<RestTimerAttributes>.activities {
            if activity.attributes.sessionID == sessionID, !updated {
                await activity.update(content)
                updated = true
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        if !updated {
            _ = try? Activity.request(attributes: RestTimerAttributes(sessionID: sessionID),
                                      content: content, pushType: nil)
        }
    }

    private nonisolated static func endAll() async {
        for activity in Activity<RestTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif
}
