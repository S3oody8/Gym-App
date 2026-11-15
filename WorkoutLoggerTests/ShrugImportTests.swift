import SwiftData
import XCTest
@testable import WorkoutLogger

/// Shrug import, tested against the real export in Fixtures/shrug_sample.csv.
@MainActor
final class ShrugImportTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!

    private func fixtureText() throws -> String {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "shrug_sample", withExtension: "csv"),
                                "fixture missing from test bundle")
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func parsedFixture() throws -> ShrugCSVParser.Result {
        try ShrugCSVParser.parse(try fixtureText(), timeZone: utc)
    }

    // MARK: Parser

    func testParsesWholeFixture() throws {
        let parsed = try parsedFixture()
        XCTAssertEqual(parsed.rows.count, 4622)
        XCTAssertEqual(parsed.unreadableLines, 0)
        XCTAssertEqual(Set(parsed.rows.map(\.startText)).count, 324)
        XCTAssertEqual(Set(parsed.rows.map(\.exercise)).count, 207)
        XCTAssertEqual(parsed.rows.filter(\.isPounds).count, 776)
        XCTAssertEqual(parsed.rows.filter(\.isTimed).map(\.exercise), Array(repeating: "Dead Hangs", count: 6))
        let first = try XCTUnwrap(parsed.rows.first)
        XCTAssertEqual(first, ShrugRow(startText: "2024-10-12 21:33",
                                       start: Date(timeIntervalSince1970: 1_728_768_780),
                                       exercise: "Incline Chest", weight: 55, isPounds: true, reps: 9, isTimed: false))
        XCTAssertTrue(parsed.rows.contains { $0.exercise == ShrugCSVParser.unnamedExercise },
                      "the name made only of U+200E becomes 'Unnamed exercise'")
        XCTAssertTrue(parsed.rows.contains { $0.weight == 16.5 && !$0.isPounds })
    }

    func testParserHelpers() throws {
        XCTAssertEqual(ShrugCSVParser.fields("a, \"b, c\", \"say \"\"hi\"\"\" ,d"), ["a", "b, c", "say \"hi\"", "d"])
        XCTAssertEqual(ShrugCSVParser.cleanName("\u{200E} Lat  Pulldown \u{200F}"), "Lat Pulldown")
        XCTAssertEqual(ShrugCSVParser.cleanName("\u{200E} "), "Unnamed exercise")
        XCTAssertThrowsError(try ShrugCSVParser.parse("Date, Exercise\n2024-01-01 10:00, X")) {
            XCTAssertEqual($0 as? ShrugCSVParser.ParseError,
                           .missingColumns(["Workout Start", "Weight", "Unit", "Reps", "Reps/Secs"]))
        }
        let messy = try ShrugCSVParser.parse(
            "Workout Start, Exercise, Weight, Unit, Reps, Reps/Secs\r\n2024-01-01 10:00, X, abc, kg, 5, reps\r\n2024-01-01 10:00, X, 50, kg, 5, reps\r\n",
            timeZone: utc)
        XCTAssertEqual(messy.rows.count, 1)
        XCTAssertEqual(messy.unreadableLines, 1)
    }

    // MARK: Planner

    func testPlanFromFixture() throws {
        let rows = try parsedFixture().rows
        let plan = ShrugImportPlanner.plan(rows: rows, mappings: [:], alreadyKg: [])
        XCTAssertEqual(plan.workouts.count, 324)
        XCTAssertEqual(plan.setCount, 4616)
        XCTAssertEqual(plan.exerciseNames.count, 206, "Dead Hangs only had timed rows")
        XCTAssertEqual(plan.skippedTimed, ["Dead Hangs": 6])

        let first = try XCTUnwrap(plan.workouts.first)
        XCTAssertEqual(first.entries.map(\.exerciseName),
                       ["Incline Chest", "Chest press", "Chest Flys", "Standing Pec Flys",
                        "Bicep Dumbbell Curl Spider", "Rope Hammer Curls", "Ab Crunches Rope"])
        XCTAssertEqual(first.entries[0].sets[0].weight, 24.9, "55 lb → 24.9 kg")
        XCTAssertEqual(first.entries[1].sets[0].weight, 45, "kg rows unchanged")

        let info = ShrugImportPlanner.exerciseInfo(rows)
        let clr = try XCTUnwrap(info.first { $0.name == "Cable Lateral Raise" })
        XCTAssertEqual(clr.poundRows, 190)
        XCTAssertEqual(clr.poundExample, 30)
        XCTAssertEqual(info.filter { $0.poundRows > 0 }.count, 65, "66 raw, minus Dead Hangs whose lb rows are all timed")
    }

    func testAlreadyKgKeepsNumbers() throws {
        let rows = try parsedFixture().rows
        let plan = ShrugImportPlanner.plan(rows: rows, mappings: [:], alreadyKg: ["Incline Chest"])
        XCTAssertEqual(plan.workouts[0].entries[0].sets[0].weight, 55)
        XCTAssertEqual(plan.workouts[0].entries[2].sets[0].weight, 27.2, "other exercises still convert (60 lb)")
    }

    func testMappingRenameMergeAndCycles() {
        let m: [String: ShrugMapping] = ["A": .rename("Alpha"), "B": .merge(into: "A"), "C": .merge(into: "D"),
                                         "D": .merge(into: "C"), "E": .rename("  ")]
        XCTAssertEqual(ShrugImportPlanner.targetName(for: "A", mappings: m), "Alpha")
        XCTAssertEqual(ShrugImportPlanner.targetName(for: "B", mappings: m), "Alpha")
        XCTAssertEqual(ShrugImportPlanner.targetName(for: "Z", mappings: m), "Z")
        XCTAssertEqual(ShrugImportPlanner.targetName(for: "E", mappings: m), "E", "blank rename = keep")
        XCTAssertNotNil(ShrugImportPlanner.targetName(for: "C", mappings: m), "cycle terminates")
        XCTAssertEqual(ShrugImportPlanner.kilograms(fromPounds: 55), 24.9)
        XCTAssertEqual(ShrugImportPlanner.kilograms(fromPounds: 0), 0)
    }

    // MARK: Importer

    func testImportFixtureThenReimportAddsNothing() async throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let rows = try parsedFixture().rows
        let plan = ShrugImportPlanner.plan(rows: rows, mappings: [:], alreadyKg: [])

        var progressCalls: [(Int, Int)] = []
        let result = try await ShrugImporter(context: context, batchSize: 500).run(plan) { progressCalls.append(($0, $1)) }
        XCTAssertEqual(result.workoutsAdded, 324)
        XCTAssertEqual(result.setsAdded, 4616)
        XCTAssertEqual(result.exercisesCreated, 206)
        XCTAssertEqual(result.skippedTimed, ["Dead Hangs": 6])
        XCTAssertEqual(result.setsAlreadyImported, 0)
        XCTAssertGreaterThanOrEqual(progressCalls.count, 10, "start + one per 500-set batch + end")
        XCTAssertEqual(progressCalls.last?.0, 4616)
        XCTAssertEqual(progressCalls.map(\.0), progressCalls.map(\.0).sorted(), "progress only moves forward")

        let fresh = ModelContext(container)
        let sets = try fresh.fetch(FetchDescriptor<WorkoutSet>())
        XCTAssertEqual(sets.count, 4616)
        XCTAssertTrue(sets.allSatisfy { $0.type == .working && $0.rir == nil })
        let sessions = try fresh.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertTrue(sessions.allSatisfy { !$0.isActive && $0.name.isEmpty })
        XCTAssertEqual(try fresh.fetchCount(FetchDescriptor<Exercise>()), 206)

        let again = try await ShrugImporter(context: context).run(plan)
        XCTAssertEqual(again.workoutsAdded, 0)
        XCTAssertEqual(again.setsAdded, 0)
        XCTAssertEqual(again.exercisesCreated, 0)
        XCTAssertEqual(again.setsAlreadyImported, 4616)
        XCTAssertEqual(try ModelContext(container).fetchCount(FetchDescriptor<WorkoutSet>()), 4616)
        XCTAssertEqual(try ModelContext(container).fetchCount(FetchDescriptor<WorkoutSession>()), 324)
    }

    func testMergeAndExistingExerciseReuse() async throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let mine = Exercise(name: "chest PRESS", equipment: .machine)
        context.insert(mine)
        try context.save()
        let rows = try parsedFixture().rows
        let plan = ShrugImportPlanner.plan(rows: rows, mappings: ["Chest Flys": .merge(into: "Standing Pec Flys")],
                                           alreadyKg: [])
        let result = try await ShrugImporter(context: context).run(plan)
        XCTAssertEqual(result.exercisesCreated, 204, "Chest press reuses mine; Chest Flys merged away")
        let names = try context.fetch(FetchDescriptor<Exercise>()).map(\.name)
        XCTAssertFalse(names.contains("Chest Flys"))
        XCTAssertFalse(names.contains("Chest press"))
        XCTAssertGreaterThan(mine.sessionEntries.count, 0)
    }

    func testFirstWorkoutOfEachExerciseHasNoPRs() async throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let plan = ShrugImportPlanner.plan(rows: try parsedFixture().rows, mappings: [:], alreadyKg: [])
        _ = try await ShrugImporter(context: context).run(plan)

        var totalBadges = 0
        for exercise in try context.fetch(FetchDescriptor<Exercise>()) {
            let inputs = ProgressQueries.prInputs(for: exercise)
            let badges = PRDetector.badges(for: inputs)
            totalBadges += badges.count
            let firstStart = inputs.map(\.sessionStart).min()
            let firstSetIDs = Set(inputs.filter { $0.sessionStart == firstStart }.map(\.id))
            XCTAssertTrue(firstSetIDs.isDisjoint(with: badges.keys), exercise.name)
        }
        XCTAssertGreaterThan(totalBadges, 0, "later workouts do get PRs")
    }
}
