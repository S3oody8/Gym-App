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
        center.add(request, withCompletionHandler: nil)
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}
