import Foundation

/// Result of a backup import.
struct ImportSummary: Equatable, Sendable {
    var addedExercises = 0
    var addedSessions = 0
    var addedTemplates = 0
    var skipped = 0

    var message: String {
        let added = addedExercises + addedSessions + addedTemplates
        if added == 0 { return "Nothing new to import. \(skipped) item\(skipped == 1 ? " was" : "s were") already here." }
        return "Added \(addedSessions) workout\(addedSessions == 1 ? "" : "s"), \(addedExercises) exercise\(addedExercises == 1 ? "" : "s") and \(addedTemplates) template\(addedTemplates == 1 ? "" : "s"). Skipped \(skipped) already here."
    }
}
