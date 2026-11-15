import Foundation

/// Debug-only launch scenarios for screenshots (`-uiScenario <name>`). Always nil in Release.
/// A scenario uses a fresh in-memory store, so real data is never touched.
enum DebugScenario: String {
    case workoutEmpty
    case workoutMid
    case workoutPopup
    case workoutDiscard
    case workoutRemoveUndo
    case exercises
    case exerciseEditor

    static let current: DebugScenario? = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-uiScenario"), args.indices.contains(index + 1) else {
            return nil
        }
        return DebugScenario(rawValue: args[index + 1])
        #else
        return nil
        #endif
    }()

    var initialTab: AppTab {
        switch self {
        case .workoutEmpty, .workoutMid, .workoutPopup, .workoutDiscard, .workoutRemoveUndo: .workout
        case .exercises, .exerciseEditor: .exercises
        }
    }
}
