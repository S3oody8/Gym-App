import SwiftData
import XCTest
@testable import WorkoutLogger

@MainActor
final class ModelSchemaTests: XCTestCase {
    func testFullGraphRoundTripsInMemory() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext

        let bench = Exercise(name: "Bench Press", primaryMuscle: "Chest",
                             secondaryMuscles: ["Triceps"], equipment: .barbell)
        context.insert(bench)

        let session = WorkoutSession()
        context.insert(session)
        let entry = SessionExercise(order: 0, exercise: bench)
        session.entries.append(entry)
        let s1 = WorkoutSet(order: 0, weight: 80, reps: 8, rir: 1,
                            loggedAt: Date(timeIntervalSince1970: 1_000))
        let s2 = WorkoutSet(order: 1, weight: 60, reps: 10, type: .drop,
                            loggedAt: Date(timeIntervalSince1970: 1_300))
        entry.sets.append(contentsOf: [s2, s1])

        let template = WorkoutTemplate(name: "Push")
        context.insert(template)
        template.items.append(TemplateExercise(order: 0, exercise: bench))
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(sessions.count, 1)
        let fetched = try XCTUnwrap(sessions.first)
        XCTAssertTrue(fetched.isActive)
        XCTAssertEqual(fetched.orderedEntries.first?.exercise?.name, "Bench Press")
        XCTAssertEqual(fetched.orderedEntries.first?.orderedSets.map(\.reps), [8, 10])
        XCTAssertEqual(fetched.orderedEntries.first?.orderedSets.last?.type, .drop)
        XCTAssertNil(fetched.orderedEntries.first?.orderedSets.last?.rir)
        XCTAssertEqual(fetched.duration, 300)

        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        XCTAssertEqual(templates.first?.orderedItems.first?.exercise?.id, bench.id)
        XCTAssertEqual(bench.sessionEntries.count, 1)
        XCTAssertEqual(bench.templateEntries.count, 1)
    }

    func testDeletingSessionCascadesToSets() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let ex = Exercise(name: "Row", primaryMuscle: "Back", equipment: .cable)
        context.insert(ex)
        let session = WorkoutSession()
        context.insert(session)
        let entry = SessionExercise(order: 0, exercise: ex)
        session.entries.append(entry)
        entry.sets.append(WorkoutSet(order: 0, weight: 50, reps: 10))
        try context.save()

        context.delete(session)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SessionExercise>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutSet>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 1)
    }
}
