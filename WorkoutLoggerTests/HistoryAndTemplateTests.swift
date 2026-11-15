import SwiftData
import XCTest
@testable import WorkoutLogger

final class TemplatePlanTests: XCTestCase {
    func testOrderAndSkipsDeletedExercises() {
        let a = UUID(), b = UUID()
        XCTAssertEqual(TemplatePlan.exerciseIDs(from: [(2, a), (0, b), (1, nil), (3, a)]), [b, a, a])
    }

    func testDurationFormatter() {
        XCTAssertEqual(DurationFormatter.string(0), "0 min")
        XCTAssertEqual(DurationFormatter.string(52 * 60 + 59), "52 min")
        XCTAssertEqual(DurationFormatter.string(65 * 60), "1 h 05 min")
    }
}

@MainActor
final class HistoryAndTemplateTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private var store: WorkoutStore { WorkoutStore(context: context) }
    private var bench: Exercise!
    private var row: Exercise!
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() async throws {
        container = try ModelSchema.makeContainer(inMemory: true)
        bench = Exercise(name: "Bench", equipment: .barbell)
        row = Exercise(name: "Row", equipment: .cable)
        context.insert(bench)
        context.insert(row)
        try context.save()
    }

    /// Finished session: row first (2 sets), then bench (1 set).
    private func makePastSession(start: Date) throws -> WorkoutSession {
        let session = try store.startSession(at: start)
        let rowEntry = try store.addEntry(row, to: session)
        let benchEntry = try store.addEntry(bench, to: session)
        try store.addSet(SetValues(weight: 60, reps: 10), to: rowEntry, at: start.addingTimeInterval(60))
        try store.addSet(SetValues(weight: 60, reps: 9), to: rowEntry, at: start.addingTimeInterval(300))
        try store.addSet(SetValues(weight: 80, reps: 8, rir: 1), to: benchEntry, at: start.addingTimeInterval(1260))
        try store.finish(session, at: start.addingTimeInterval(1500))
        return session
    }

    private func freshCount<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<T>())
    }

    // MARK: Templates

    func testSaveTemplateKeepsOnlyExerciseListAndOrder() throws {
        let session = try makePastSession(start: t0)
        let template = try store.saveTemplate(from: session, name: "Pull/Push")
        XCTAssertEqual(template.orderedItems.map { $0.exercise?.name }, ["Row", "Bench"])
        XCTAssertEqual(try freshCount(WorkoutTemplate.self), 1)
        XCTAssertEqual(try freshCount(WorkoutSet.self), 3, "template copies no sets")
    }

    func testStartFromTemplateHasNoSetsAndPrefillsFromHistory() throws {
        let past = try makePastSession(start: t0)
        let template = try store.saveTemplate(from: past, name: "T")
        let session = try store.startSession(from: template, at: t0.addingTimeInterval(86_400))
        XCTAssertTrue(session.isActive)
        XCTAssertEqual(session.orderedEntries.map { $0.exercise?.name }, ["Row", "Bench"])
        XCTAssertTrue(session.allSets.isEmpty, "no sets, no weights or reps pre-filled")

        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        vm.openAddSet(for: session.orderedEntries[0])
        XCTAssertEqual(vm.entryRequest?.initial, SetValues(weight: 60, reps: 9), "last logged set in history")
        vm.openAddSet(for: session.orderedEntries[1])
        XCTAssertEqual(vm.entryRequest?.initial, SetValues(weight: 80, reps: 8), "RIR not carried over")
    }

    func testSaveTemplateFromViewModelCanBeUndone() throws {
        let session = try makePastSession(start: t0)
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        XCTAssertTrue(vm.canSaveTemplate)
        vm.saveTemplate(named: "   ")
        XCTAssertEqual(try freshCount(WorkoutTemplate.self), 0, "blank name ignored")
        vm.saveTemplate(named: " Upper ")
        let saved = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        XCTAssertEqual(saved.map(\.name), ["Upper"])
        vm.undo()
        XCTAssertEqual(try freshCount(WorkoutTemplate.self), 0)
        XCTAssertEqual(try freshCount(Exercise.self), 2, "exercises untouched")
    }

    // MARK: Editing past sessions

    func testMovingStartShiftsEverythingAndKeepsDuration() throws {
        let session = try makePastSession(start: t0)
        XCTAssertEqual(session.duration, 1200)
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        let newStart = t0.addingTimeInterval(-3 * 86_400 + 1800)
        vm.moveStart(to: newStart)
        XCTAssertEqual(session.startedAt, newStart)
        XCTAssertEqual(session.finishedAt, newStart.addingTimeInterval(1500))
        XCTAssertEqual(session.allSets.map(\.loggedAt).min(), newStart.addingTimeInterval(60))
        XCTAssertEqual(session.duration, 1200)

        let persisted = try ModelContext(container).fetch(FetchDescriptor<WorkoutSession>()).first
        XCTAssertEqual(persisted?.startedAt, newStart)

        vm.undo()
        XCTAssertEqual(session.startedAt, t0)
        XCTAssertEqual(session.allSets.map(\.loggedAt).min(), t0.addingTimeInterval(60))
    }

    func testEditingPastSessionRecomputesDurationWithoutRestAlerts() throws {
        let session = try makePastSession(start: t0)
        let fake = FakeRestAlerts()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: fake)
        XCTAssertFalse(vm.isLive)
        let benchEntry = session.orderedEntries[1]

        vm.quickAdd(to: benchEntry, minus: 1)
        XCTAssertEqual(benchEntry.orderedSets.map(\.reps), [8, 7])
        XCTAssertEqual(benchEntry.orderedSets.last?.loggedAt, t0.addingTimeInterval(1260),
                       "new set takes the session's last set time, not now")
        XCTAssertEqual(session.duration, 1200)

        let firstRowSet = session.orderedEntries[0].orderedSets[0]
        vm.deleteSet(firstRowSet, from: session.orderedEntries[0])
        XCTAssertEqual(session.duration, 960, "duration recomputed from remaining sets")

        let set = benchEntry.orderedSets[0]
        vm.submit(SetValues(weight: 85, reps: 6), for: SetEntryRequest(
            entryID: benchEntry.id, setID: set.id, exerciseName: "Bench", initial: set.values, increment: 2.5))
        XCTAssertEqual(set.values, SetValues(weight: 85, reps: 6))
        XCTAssertTrue(fake.scheduled.isEmpty && fake.cancelCount == 0, "no rest alerts for past sessions")
        XCTAssertFalse(session.isActive, "stays finished")
    }

    func testLastTextComparesWithSessionBeforeThePastOne() throws {
        let older = try makePastSession(start: t0)
        let newer = try makePastSession(start: t0.addingTimeInterval(7 * 86_400))
        older.orderedEntries[1].orderedSets[0].weight = 75
        try context.save()
        let vm = SessionEditorViewModel(session: newer, context: context, restAlerts: FakeRestAlerts())
        XCTAssertEqual(vm.lastText(for: newer.orderedEntries[1], index: 0), "Last: 75×8")
        let olderVM = SessionEditorViewModel(session: older, context: context, restAlerts: FakeRestAlerts())
        XCTAssertNil(olderVM.lastText(for: older.orderedEntries[1], index: 0))
    }

    // MARK: Deleting sessions

    func testDeleteSessionWithUndoRestoresEverything() throws {
        let session = try makePastSession(start: t0)
        let ids = (session.id, session.orderedEntries.map(\.id), session.allSets.map(\.id).sorted { $0.uuidString < $1.uuidString })
        let history = HistoryViewModel()

        history.delete(session, in: context)
        XCTAssertEqual(try freshCount(WorkoutSession.self), 0)
        XCTAssertEqual(try freshCount(WorkoutSet.self), 0)
        XCTAssertEqual(try freshCount(Exercise.self), 2)
        XCTAssertNotNil(history.deletedSnapshot)

        history.undoDelete(in: context)
        XCTAssertNil(history.deletedSnapshot)
        let restored = try XCTUnwrap(try context.fetch(FetchDescriptor<WorkoutSession>()).first)
        XCTAssertEqual(restored.id, ids.0)
        XCTAssertEqual(restored.orderedEntries.map(\.id), ids.1)
        XCTAssertEqual(restored.allSets.map(\.id).sorted { $0.uuidString < $1.uuidString }, ids.2)
        XCTAssertEqual(restored.orderedEntries.map { $0.exercise?.name }, ["Row", "Bench"])
        XCTAssertEqual(restored.orderedEntries[0].orderedSets.map(\.reps), [10, 9])
        XCTAssertEqual(restored.orderedEntries[1].orderedSets.first?.rir, 1)
        XCTAssertEqual(restored.finishedAt, t0.addingTimeInterval(1500))
        XCTAssertEqual(restored.duration, 1200)
        XCTAssertEqual(try freshCount(WorkoutSet.self), 3)
    }
}
