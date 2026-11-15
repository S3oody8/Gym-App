import SwiftData
import XCTest
@testable import WorkoutLogger

@MainActor
final class ActiveWorkoutTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private var store: WorkoutStore { WorkoutStore(context: context) }
    private var bench: Exercise!

    override func setUp() async throws {
        container = try ModelSchema.makeContainer(inMemory: true)
        bench = Exercise(name: "Bench", primary: .chest, equipment: .barbell, weightIncrement: 2.5)
        context.insert(bench)
        try context.save()
    }

    /// Re-reads from a fresh context to prove changes were saved.
    private func persistedSetCount() throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<WorkoutSet>())
    }

    func testStartAndActiveSession() throws {
        XCTAssertNil(store.activeSession())
        let session = try store.startSession()
        XCTAssertEqual(store.activeSession()?.id, session.id)
        try store.finish(session)
        XCTAssertNil(store.activeSession())
    }

    func testEverySetChangeIsPersisted() throws {
        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        vm.addExercise(bench)
        let entry = try XCTUnwrap(session.orderedEntries.first)

        vm.submit(SetValues(weight: 80, reps: 8), for: request(entry))
        XCTAssertEqual(try persistedSetCount(), 1)
        vm.quickAdd(to: entry, minus: 1)
        vm.quickAdd(to: entry, minus: 3)
        XCTAssertEqual(entry.orderedSets.map(\.reps), [8, 7, 4])
        XCTAssertEqual(entry.orderedSets.map(\.weight), [80, 80, 80])
        XCTAssertEqual(try persistedSetCount(), 3)
        XCTAssertEqual(vm.addedSetCount, 3)

        let middle = entry.orderedSets[1]
        vm.deleteSet(middle, from: entry)
        XCTAssertEqual(try persistedSetCount(), 2)
        XCTAssertEqual(entry.orderedSets.map(\.order), [0, 1])
        XCTAssertNil(vm.saveErrorMessage)
    }

    func testQuickAddNeedsASetInThisSession() throws {
        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        vm.addExercise(bench)
        let entry = try XCTUnwrap(session.orderedEntries.first)
        XCTAssertFalse(vm.canQuickAdd(entry))
        vm.quickAdd(to: entry, minus: 1)
        XCTAssertTrue(entry.sets.isEmpty)
    }

    func testUndoAddEditDelete() throws {
        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        vm.addExercise(bench)
        let entry = try XCTUnwrap(session.orderedEntries.first)
        vm.submit(SetValues(weight: 80, reps: 8), for: request(entry))
        vm.submit(SetValues(weight: 80, reps: 6), for: request(entry))

        vm.undo()
        XCTAssertEqual(entry.orderedSets.map(\.reps), [8])
        XCTAssertNil(vm.undoAction)

        let set = try XCTUnwrap(entry.orderedSets.first)
        vm.submit(SetValues(weight: 85, reps: 5, rir: 1, type: .drop), for: request(entry, editing: set))
        XCTAssertEqual(set.values, SetValues(weight: 85, reps: 5, rir: 1, type: .drop))
        vm.undo()
        XCTAssertEqual(set.values, SetValues(weight: 80, reps: 8))

        vm.submit(SetValues(weight: 80, reps: 7), for: request(entry))
        let firstID = entry.orderedSets[0].id
        vm.deleteSet(entry.orderedSets[0], from: entry)
        XCTAssertEqual(entry.orderedSets.map(\.reps), [7])
        vm.undo()
        XCTAssertEqual(entry.orderedSets.map(\.reps), [8, 7], "restored at its original position")
        XCTAssertEqual(entry.orderedSets[0].id, firstID, "same id after restore")
        XCTAssertEqual(try persistedSetCount(), 2)
    }

    func testRemoveExerciseAndUndo() throws {
        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        let row = Exercise(name: "Row", primary: .upperBack, equipment: .cable)
        context.insert(row)
        vm.addExercise(bench)
        vm.addExercise(row)
        let benchEntry = session.orderedEntries[0]
        vm.submit(SetValues(weight: 80, reps: 8), for: request(benchEntry))

        vm.removeEntry(benchEntry)
        XCTAssertEqual(session.orderedEntries.map { $0.exercise?.name }, ["Row"])
        XCTAssertEqual(try persistedSetCount(), 0)

        vm.undo()
        XCTAssertEqual(session.orderedEntries.map { $0.exercise?.name }, ["Bench", "Row"])
        XCTAssertEqual(session.orderedEntries[0].orderedSets.map(\.reps), [8])
        XCTAssertEqual(try persistedSetCount(), 1)
    }

    func testLastSessionLookupAndPrefill() throws {
        let old = WorkoutSession(startedAt: .now.addingTimeInterval(-20 * 86_400), finishedAt: .now)
        let recent = WorkoutSession(startedAt: .now.addingTimeInterval(-7 * 86_400), finishedAt: .now)
        context.insert(old)
        context.insert(recent)
        let oldEntry = SessionExercise(order: 0, exercise: bench)
        old.entries.append(oldEntry)
        oldEntry.sets.append(WorkoutSet(order: 0, weight: 70, reps: 10))
        let recentEntry = SessionExercise(order: 0, exercise: bench)
        recent.entries.append(recentEntry)
        recentEntry.sets.append(contentsOf: [WorkoutSet(order: 0, weight: 80, reps: 8),
                                             WorkoutSet(order: 1, weight: 80, reps: 7)])
        try context.save()

        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        vm.addExercise(bench)
        let entry = try XCTUnwrap(session.orderedEntries.first)
        XCTAssertEqual(vm.lastText(for: entry, index: 0), "Last: 80×8")
        XCTAssertEqual(vm.lastText(for: entry, index: 1), "Last: 80×7")
        XCTAssertNil(vm.lastText(for: entry, index: 2))

        vm.openAddSet(for: entry)
        XCTAssertEqual(vm.entryRequest?.initial, SetValues(weight: 80, reps: 7), "history fallback")
        XCTAssertEqual(vm.entryRequest?.increment, 2.5)
        vm.submit(SetValues(weight: 85, reps: 5), for: try XCTUnwrap(vm.entryRequest))
        vm.openAddSet(for: entry)
        XCTAssertEqual(vm.entryRequest?.initial, SetValues(weight: 85, reps: 5), "this session first")
    }

    func testDiscardEmptyWorkout() throws {
        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        vm.discard()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutSession>()), 0)
    }

    func testDuration() throws {
        let session = try store.startSession()
        let entry = try store.addEntry(bench, to: session)
        let t0 = Date(timeIntervalSince1970: 0)
        try store.addSet(SetValues(weight: 80, reps: 8), to: entry, at: t0)
        try store.addSet(SetValues(weight: 80, reps: 8), to: entry, at: t0.addingTimeInterval(1800))
        XCTAssertEqual(session.duration, 1800)
    }

    private func request(_ entry: SessionExercise, editing set: WorkoutSet? = nil) -> SetEntryRequest {
        SetEntryRequest(entryID: entry.id, setID: set?.id, exerciseName: "Bench",
                        initial: set?.values, increment: 2.5)
    }
}
