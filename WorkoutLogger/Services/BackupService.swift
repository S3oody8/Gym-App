import Foundation
import SwiftData

/// Builds backups / CSV from the store and imports backups. Imports match on UUID and skip
/// anything that already exists — they never overwrite.
@MainActor
struct BackupService {
    let context: ModelContext

    // MARK: Export

    func makeBackup(now: Date = .now) throws -> BackupFile {
        let exercises = try context.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)]))
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt)]))
        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.name)]))
        return BackupFile(
            exportedAt: now,
            exercises: exercises.map {
                .init(id: $0.id, name: $0.name, equipment: $0.equipmentRaw, weightIncrement: $0.weightIncrement,
                      createdAt: $0.createdAt, isArchived: $0.isArchived)
            },
            sessions: sessions.map { session in
                .init(id: session.id, name: session.name, startedAt: session.startedAt,
                      finishedAt: session.finishedAt,
                      entries: session.orderedEntries.map { entry in
                          .init(id: entry.id, order: entry.order, exerciseID: entry.exercise?.id,
                                sets: entry.orderedSets.map {
                                    .init(id: $0.id, order: $0.order, weight: $0.weight, reps: $0.reps,
                                          rir: $0.rir, type: $0.typeRaw, loggedAt: $0.loggedAt)
                                })
                      })
            },
            templates: templates.map { template in
                .init(id: template.id, name: template.name, createdAt: template.createdAt,
                      items: template.orderedItems.map { .init(id: $0.id, order: $0.order, exerciseID: $0.exercise?.id) })
            }
        )
    }

    /// One CSV row per set, sessions oldest first.
    func csvRows() throws -> [CSVRow] {
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt)]))
        return sessions.flatMap { session in
            session.orderedEntries.flatMap { entry in
                entry.orderedSets.enumerated().map { index, set in
                    CSVRow(date: session.startedAt, session: session.name,
                           exercise: entry.exercise?.name ?? "Deleted exercise",
                           setNumber: index + 1, type: set.type, weight: set.weight, reps: set.reps, rir: set.rir)
                }
            }
        }
    }

    // MARK: Import

    func importBackup(_ file: BackupFile) throws -> ImportSummary {
        defer { PRCache.shared(for: context).invalidateAll() }
        var summary = ImportSummary()
        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
        var exerciseByID = Dictionary(existingExercises.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var exerciseByName = Dictionary(existingExercises.map { (ExerciseDraft.nameKey($0.name), $0) },
                                        uniquingKeysWith: { a, _ in a })
        let sessionIDs = Set(try context.fetch(FetchDescriptor<WorkoutSession>()).map(\.id))
        let entryIDs = Set(try context.fetch(FetchDescriptor<SessionExercise>()).map(\.id))
        let setIDs = Set(try context.fetch(FetchDescriptor<WorkoutSet>()).map(\.id))
        let templateIDs = Set(try context.fetch(FetchDescriptor<WorkoutTemplate>()).map(\.id))
        let templateItemIDs = Set(try context.fetch(FetchDescriptor<TemplateExercise>()).map(\.id))
        let hasActiveSession = try context.fetchCount(
            FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.finishedAt == nil })) > 0

        // Exercises: skip existing ids; an imported exercise whose name matches an existing one
        // (trimmed, case-insensitive) is mapped onto it instead of creating a duplicate name.
        for dto in file.exercises {
            if exerciseByID[dto.id] != nil { summary.skipped += 1; continue }
            if let sameName = exerciseByName[ExerciseDraft.nameKey(dto.name)] {
                exerciseByID[dto.id] = sameName
                summary.skipped += 1
                continue
            }
            let exercise = Exercise(id: dto.id, name: dto.name.trimmingCharacters(in: .whitespacesAndNewlines),
                                    equipment: Equipment(rawValue: dto.equipment) ?? .machine,
                                    weightIncrement: dto.weightIncrement > 0 ? dto.weightIncrement : 2.5,
                                    createdAt: dto.createdAt, isArchived: dto.isArchived)
            context.insert(exercise)
            exerciseByID[dto.id] = exercise
            exerciseByName[ExerciseDraft.nameKey(dto.name)] = exercise
            summary.addedExercises += 1
        }

        // Sessions (with their entries and sets).
        var activeTaken = hasActiveSession
        for dto in file.sessions {
            if sessionIDs.contains(dto.id) { summary.skipped += 1; continue }
            var finishedAt = dto.finishedAt
            if finishedAt == nil {
                // Never create a second live workout: close it at its last set (or start).
                if activeTaken {
                    finishedAt = dto.entries.flatMap(\.sets).map(\.loggedAt).max() ?? dto.startedAt
                } else {
                    activeTaken = true
                }
            }
            let session = WorkoutSession(id: dto.id, name: dto.name, startedAt: dto.startedAt, finishedAt: finishedAt)
            context.insert(session)
            for entryDTO in dto.entries where !entryIDs.contains(entryDTO.id) {
                let entry = SessionExercise(id: entryDTO.id, order: entryDTO.order,
                                            exercise: entryDTO.exerciseID.flatMap { exerciseByID[$0] })
                session.entries.append(entry)
                for setDTO in entryDTO.sets where !setIDs.contains(setDTO.id) {
                    entry.sets.append(WorkoutSet(id: setDTO.id, order: setDTO.order, weight: setDTO.weight,
                                                 reps: setDTO.reps, rir: setDTO.rir,
                                                 type: SetType(rawValue: setDTO.type) ?? .working,
                                                 loggedAt: setDTO.loggedAt))
                }
            }
            summary.addedSessions += 1
        }

        // Templates.
        for dto in file.templates {
            if templateIDs.contains(dto.id) { summary.skipped += 1; continue }
            let template = WorkoutTemplate(id: dto.id, name: dto.name, createdAt: dto.createdAt)
            context.insert(template)
            for item in dto.items where !templateItemIDs.contains(item.id) {
                template.items.append(TemplateExercise(id: item.id, order: item.order,
                                                       exercise: item.exerciseID.flatMap { exerciseByID[$0] }))
            }
            summary.addedTemplates += 1
        }

        try context.save()
        return summary
    }
}
