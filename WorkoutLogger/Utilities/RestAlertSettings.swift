import Foundation

/// Rest alert settings as stored in `UserDefaults` (same keys as `@AppStorage`).
struct RestAlertSettings: Equatable, Sendable {
    var enabled: Bool
    var seconds: Int

    static func current(from defaults: UserDefaults = .standard) -> RestAlertSettings {
        let enabled = defaults.object(forKey: SettingsKeys.restAlertEnabled) as? Bool
            ?? SettingsKeys.defaultRestAlertEnabled
        let seconds = defaults.object(forKey: SettingsKeys.restAlertSeconds) as? Int
            ?? SettingsKeys.defaultRestAlertSeconds
        return RestAlertSettings(enabled: enabled, seconds: RestTimerMath.clampAlert(seconds))
    }
}
