import Foundation

/// Debug-only launch scenarios for screenshots (`-uiScenario <name>`). Always nil in Release.
/// A scenario uses a fresh in-memory store, so real data is never touched.
enum DebugScenario: String {
    case workoutEmpty
    case workoutMid
    case workoutPopup
    case workoutDiscard
    case workoutRemoveUndo
    case restAlert
    case settings
    case history
    case historyDetail
    case historyDeleteFromDetail
    case templatePicker
    case progress
    case exerciseProgress
    case shrugMapping
    case shrugProgress
    case shrugSummary
    case shrugHistory
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

    /// Graph metric to open with (`-metric e1RM|top|volume`), Debug only.
    static let initialMetric: ProgressMetric? = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-metric"), args.indices.contains(index + 1) else { return nil }
        switch args[index + 1] {
        case "top": return .topSet
        case "volume": return .volume
        default: return .e1RM
        }
        #else
        return nil
        #endif
    }()

    /// Contents of the file passed with `-shrugFile <path>`, Debug only.
    static let shrugFileText: String? = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-shrugFile"), args.indices.contains(index + 1) else { return nil }
        return try? String(contentsOfFile: args[index + 1], encoding: .utf8)
        #else
        return nil
        #endif
    }()

    var initialTab: AppTab {
        switch self {
        case .workoutEmpty, .workoutMid, .workoutPopup, .workoutDiscard, .workoutRemoveUndo, .restAlert: .workouts
        case .settings: .settings
        case .history, .historyDetail, .historyDeleteFromDetail, .templatePicker, .shrugHistory: .workouts
        case .progress: .progress
        case .exerciseProgress: .exercises
        case .shrugMapping, .shrugProgress, .shrugSummary: .settings
        case .exercises, .exerciseEditor: .exercises
        }
    }

    /// Scenarios that start with the live workout open full screen.
    var opensWorkout: Bool {
        [.workoutEmpty, .workoutMid, .workoutPopup, .workoutDiscard, .workoutRemoveUndo, .restAlert].contains(self)
    }
}
