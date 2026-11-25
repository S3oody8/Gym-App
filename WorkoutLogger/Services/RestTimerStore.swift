import Foundation
import Observation

/// The live workout's rest timer, shared by the dock, the rest sheet and the mini-bar.
/// Owns the per-period alert time (±30 s), Skip, the "Rest over" notification and the
/// lock screen Live Activity.
@MainActor
@Observable
final class RestTimerStore {
    static let shared = RestTimerStore()
    static let defaultsKey = "restPeriod"

    private(set) var period: RestPeriod?

    private let alerts: RestAlertScheduling
    private let activities: RestActivityControlling
    private let settings: () -> RestAlertSettings
    private let defaults: UserDefaults?

    init(alerts: RestAlertScheduling? = nil,
         activities: RestActivityControlling? = nil,
         settings: @escaping () -> RestAlertSettings = { RestAlertSettings.current() },
         defaults: UserDefaults? = .standard) {
        self.alerts = alerts ?? RestAlertNotifier.shared
        self.activities = activities ?? RestActivityController.shared
        self.settings = settings
        self.defaults = defaults
        if let data = defaults?.data(forKey: Self.defaultsKey) {
            period = try? JSONDecoder().decode(RestPeriod.self, from: data)
        }
    }

    /// The period to show for this session, or nil (no set yet, skipped, another session).
    func visiblePeriod(for sessionID: UUID?) -> RestPeriod? {
        guard let period, period.sessionID == sessionID, !period.skipped else { return nil }
        return period
    }

    /// Re-aligns with the session's latest set after a set is added, deleted or undone.
    /// A different latest set starts a new period with the alert time from Settings.
    func sync(sessionID: UUID, lastSetAt: Date?, now: Date = .now) {
        guard let lastSetAt else { return end() }
        if let period, period.sessionID == sessionID, period.start == lastSetAt { return }
        set(RestPeriod(sessionID: sessionID, start: lastSetAt, alertSeconds: settings().seconds), now: now)
    }

    /// −30 s / +30 s: moves this period's alert time (see `RestTimerMath.adjustedAlert`).
    func adjust(by delta: Int, now: Date = .now) {
        guard var period, !period.skipped else { return }
        let elapsed = RestTimerMath.elapsed(since: period.start, now: now)
        period.alertSeconds = RestTimerMath.adjustedAlert(period.alertSeconds, by: delta, elapsed: elapsed)
        set(period, now: now)
    }

    /// Skip rest: hides the timer until the next set and cancels its alert and Live Activity.
    func skip() {
        guard var period else { return }
        period.skipped = true
        set(period, now: .now)
    }

    /// Re-applies the current period when the app goes to the background or comes back:
    /// re-schedules a still-future alert and refreshes the Live Activity. Clears a period left
    /// over from a workout that is no longer active.
    func resync(activeSessionID: UUID?, now: Date = .now) {
        guard let period else { return }
        guard period.sessionID == activeSessionID else { return end() }
        guard !period.skipped else { return }
        set(period, now: now)
    }

    /// Finish or discard: clears everything.
    func end() {
        period = nil
        defaults?.removeObject(forKey: Self.defaultsKey)
        alerts.cancel()
        activities.end()
    }

    private func set(_ new: RestPeriod, now: Date) {
        period = new
        if let data = try? JSONEncoder().encode(new) { defaults?.set(data, forKey: Self.defaultsKey) }
        let current = settings()
        if !new.skipped,
           let date = RestTimerMath.fireDate(lastSetAt: new.start, alertSeconds: new.alertSeconds,
                                             enabled: current.enabled, now: now) {
            alerts.schedule(at: date, restSeconds: new.alertSeconds)
        } else {
            alerts.cancel()
        }
        if new.skipped {
            activities.end()
        } else {
            activities.show(new)
        }
    }
}
