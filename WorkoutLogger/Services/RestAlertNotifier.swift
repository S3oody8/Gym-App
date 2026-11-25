import Foundation
import UserNotifications

/// Local-notification implementation of the rest alert. Only one is ever pending,
/// so each rest period produces at most one notification.
@MainActor
final class RestAlertNotifier: RestAlertScheduling {
    static let shared = RestAlertNotifier()
    static let identifier = "rest-timer"

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// True when the user has turned notifications off for the app (the alert can't fire).
    func isDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    func schedule(at date: Date, restSeconds: Int) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { cancel(); return }
        let content = UNMutableNotificationContent()
        content.title = "Rest over"
        content.body = "\(RestTimerMath.format(TimeInterval(restSeconds))) rest done. Time for your next set."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        let center = center
        Task {
            // If permission was never asked (e.g. the workout was resumed after a relaunch),
            // ask now so this and later alerts can show.
            if await center.notificationSettings().authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
            try? await center.add(request)
        }
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}
