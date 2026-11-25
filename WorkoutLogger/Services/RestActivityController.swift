import Foundation

/// Live Activity for the rest timer. Filled in by step C2; until then it does nothing.
@MainActor
final class RestActivityController: RestActivityControlling {
    static let shared = RestActivityController()

    func show(_ period: RestPeriod) {}
    func end() {}
}
