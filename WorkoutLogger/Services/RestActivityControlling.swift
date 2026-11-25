import Foundation

/// Starts, updates and ends the rest-timer Live Activity (a no-op without `LIVEACTIVITY`).
@MainActor
protocol RestActivityControlling {
    /// Starts the activity for this period, or updates the running one.
    func show(_ period: RestPeriod)
    func end()
}
