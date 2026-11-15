import Foundation

/// Full-database backup (JSON). Every record keeps its UUID so imports can de-duplicate.
struct BackupFile: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version: Int = BackupFile.currentVersion
    var exportedAt: Date
    var exercises: [Exercise]
    var sessions: [Session]
    var templates: [Template]

    struct Exercise: Codable, Equatable, Sendable {
        var id: UUID
        var name: String
        var equipment: String
        var weightIncrement: Double
        var createdAt: Date
        var isArchived: Bool
    }

    struct Session: Codable, Equatable, Sendable {
        var id: UUID
        var name: String
        var startedAt: Date
        var finishedAt: Date?
        var entries: [Entry]
    }

    struct Entry: Codable, Equatable, Sendable {
        var id: UUID
        var order: Int
        var exerciseID: UUID?
        var sets: [Set]
    }

    struct Set: Codable, Equatable, Sendable {
        var id: UUID
        var order: Int
        var weight: Double
        var reps: Int
        var rir: Int?
        var type: String
        var loggedAt: Date
    }

    struct Template: Codable, Equatable, Sendable {
        var id: UUID
        var name: String
        var createdAt: Date
        var items: [TemplateItem]
    }

    struct TemplateItem: Codable, Equatable, Sendable {
        var id: UUID
        var order: Int
        var exerciseID: UUID?
    }
}
