import Foundation

/// The last undoable action on the active workout screen.
enum WorkoutUndoAction: Equatable, Sendable {
    case addedSet(setID: UUID)
    case editedSet(setID: UUID, previous: SetValues)
    case deletedSet(entryID: UUID, snapshot: SetSnapshot)
    case addedEntry(entryID: UUID)
    case removedEntry(EntrySnapshot)
    case movedSession(previousStart: Date)
    case savedTemplate(templateID: UUID)

    var message: String {
        switch self {
        case .addedSet: "Set added"
        case .editedSet: "Set updated"
        case .deletedSet: "Set deleted"
        case .addedEntry: "Exercise added"
        case .removedEntry: "Exercise removed"
        case .movedSession: "Date changed"
        case .savedTemplate: "Template saved"
        }
    }
}
