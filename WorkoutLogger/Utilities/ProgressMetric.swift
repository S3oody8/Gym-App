import Foundation

/// Graph metric on the per-exercise screen.
enum ProgressMetric: String, CaseIterable, Identifiable, Sendable {
    case e1RM = "e1RM"
    case topSet = "Top set"
    case volume = "Volume"

    var id: String { rawValue }
}
