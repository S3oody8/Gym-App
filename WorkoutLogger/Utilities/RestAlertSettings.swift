import Foundation

/// Rest alert settings as stored in `UserDefaults` (same keys as `@AppStorage`).
struct RestAlertSettings: Equatable, Sendable {
    var enabled: Bool
    var seconds: Int

    static func current(from defaults: UserDefaults = .standard) -> RestAlertSettings {
        // `bool(forKey:)` / `integer(forKey:)` also accept string values (e.g. launch arguments).
        let enabled = defaults.object(forKey: SettingsKeys.restAlertEnabled) == nil
            ? SettingsKeys.defaultRestAlertEnabled
            : defaults.bool(forKey: SettingsKeys.restAlertEnabled)
        let seconds = defaults.object(forKey: SettingsKeys.restAlertSeconds) == nil
            ? SettingsKeys.defaultRestAlertSeconds
            : defaults.integer(forKey: SettingsKeys.restAlertSeconds)
        return RestAlertSettings(enabled: enabled, seconds: RestTimerMath.clampAlert(seconds))
    }
}
