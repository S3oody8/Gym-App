import Foundation
import Observation
import SwiftData

/// Shrug import flow: load file → mapping screen → batched import with progress → summary.
@MainActor
@Observable
final class ShrugImportViewModel {
    enum Phase: Equatable {
        case mapping
        case importing(done: Int, total: Int)
        case finished(ShrugImportResult)
        case failed(String)
    }

    private(set) var phase: Phase = .mapping
    private(set) var rows: [ShrugRow] = []
    private(set) var unreadableLines = 0
    private(set) var exercises: [ShrugExerciseInfo] = []
    var mappings: [String: ShrugMapping] = [:]
    /// Exercises whose lb rows are really kg (mislabelled). Default: convert.
    var alreadyKg: Set<String> = []
    var searchText = ""

    init(text: String, timeZone: TimeZone = .current) {
        do {
            let parsed = try ShrugCSVParser.parse(text, timeZone: timeZone)
            rows = parsed.rows
            unreadableLines = parsed.unreadableLines
            exercises = ShrugImportPlanner.exerciseInfo(parsed.rows)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    var poundExercises: [ShrugExerciseInfo] { exercises.filter { $0.poundRows > 0 } }
    var timedExercises: [ShrugExerciseInfo] { exercises.filter { $0.timedRows > 0 } }
    var workoutCount: Int { Set(rows.filter { !$0.isTimed }.map(\.startText)).count }
    var importableSetCount: Int { rows.filter { !$0.isTimed }.count }

    var visibleExercises: [ShrugExerciseInfo] {
        exercises.filter { ExerciseSearch.matches(name: $0.name, query: searchText) }
    }

    func target(for name: String) -> String {
        ShrugImportPlanner.targetName(for: name, mappings: mappings)
    }

    /// Names an exercise can be merged into: existing exercises plus other Shrug targets.
    func mergeTargets(for name: String, existing: [Exercise]) -> [String] {
        var seen: Set<String> = []
        var names: [String] = []
        for candidate in existing.filter({ !$0.isArchived }).map(\.name) + exercises.map({ target(for: $0.name) }) {
            let key = ExerciseDraft.nameKey(candidate)
            guard key != ExerciseDraft.nameKey(target(for: name)), seen.insert(key).inserted else { continue }
            names.append(candidate)
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func convertsPounds(_ name: String) -> Bool { !alreadyKg.contains(name) }

    func setConvertsPounds(_ convert: Bool, for name: String) {
        if convert { alreadyKg.remove(name) } else { alreadyKg.insert(name) }
    }

    func plan() -> ShrugPlan {
        ShrugImportPlanner.plan(rows: rows, mappings: mappings, alreadyKg: alreadyKg)
    }

    func startImport(context: ModelContext, batchSize: Int = 500, batchDelay: Duration = .zero) async {
        let plan = plan()
        phase = .importing(done: 0, total: plan.setCount)
        do {
            let importer = ShrugImporter(context: context, batchSize: batchSize, batchDelay: batchDelay)
            let result = try await importer.run(plan, unreadableLines: unreadableLines) { done, total in
                self.phase = .importing(done: done, total: total)
            }
            phase = .finished(result)
        } catch {
            context.rollback()
            phase = .failed(error.localizedDescription)
        }
    }
}
