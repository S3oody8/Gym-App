import ActivityKit
import Foundation

/// Live Activity data for the rest timer, shared by the app and the RestTimerWidget extension.
/// Updates are local only (no push).
struct RestTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Time of the set that started this rest period; the activity counts up from here.
        var start: Date
        /// "Alert at" time, in seconds after `start`.
        var alertSeconds: Int
    }

    /// The workout this rest timer belongs to.
    var sessionID: UUID
}
