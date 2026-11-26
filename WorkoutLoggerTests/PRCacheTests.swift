import SwiftData
import XCTest
@testable import WorkoutLogger

/// The single-pass PR detector matches the old quadratic one, and the cache stays correct
/// through set / session changes.
final class PRDetectorEquivalenceTests: XCTestCase {
    /// The v1.1 algorithm, kept here as the reference.
    private func quadratic(_ sets: [PRInputSet]) -> [UUID: PRBadges] {
        let ordered = sets.filter { $0.values.type == .working }.sorted {
            if $0.sessionStart != $1.sessionStart { return $0.sessionStart < $1.sessionStart }
            if $0.sessionID != $1.sessionID { return $0.sessionID.uuidString < $1.sessionID.uuidString }
            return $0.order < $1.order
        }
        guard let firstSession = ordered.first?.sessionID else { return [:] }
        var result: [UUID: PRBadges] = [:]
        var earlier: [SetValues] = []
        for set in ordered {
            defer { earlier.append(set.values) }
            guard set.sessionID != firstSession, !earlier.isEmpty else { continue }
            var badges: PRBadges = []
            let w = set.values.weight
            if let maxWeight = earlier.map(\.weight).max(), w > maxWeight { badges.insert(.weight) }
            let atOrAbove = earlier.filter { $0.weight >= w }
            if let maxReps = atOrAbove.map(\.reps).max(), set.values.reps > maxReps { badges.insert(.reps) }
            if !badges.isEmpty { result[set.id] = badges }
        }
        return result
    }

    private func randomSets(_ count: Int, seed: UInt64) -> [PRInputSet] {
        var state = seed
        func random(_ n: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(n))
        }
        let sessions = (0..<(count / 5)).map { _ in UUID() }
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        return (0..<count).map { i in
            let session = random(sessions.count)
            return PRInputSet(id: UUID(), sessionID: sessions[session],
                              sessionStart: t0.addingTimeInterval(Double(session / 2) * 86_400), // some share a start
                              order: random(8),
                              values: SetValues(weight: 40 + Double(random(25)) * 2.5, reps: 1 + random(15),
                                                type: random(6) == 0 ? .drop : .working))
        }
    }

    func testMatchesTheQuadraticAlgorithmOnRandomSets() {
        for seed in [1, 7, 42] as [UInt64] {
            let sets = randomSets(2_000, seed: seed)
            let expected = quadratic(sets)
            XCTAssertFalse(expected.isEmpty)
            XCTAssertEqual(PRDetector.badges(for: sets), expected, "seed \(seed)")
        }
    }

    func testTiming2000Sets() {
        let sets = randomSets(2_000, seed: 3)
        measure { _ = PRDetector.badges(for: sets) }
    }
}

@MainActor
final class PRCacheTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    func testBadgesCountsAndSummariesFollowChanges() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let store = WorkoutStore(context: context)
        let cache = PRCache.shared(for: context)
        XCTAssertTrue(cache === PRCache.shared(for: context), "one cache per context")
        let bench = Exercise(name: "Bench", equipment: .barbell)
        context.insert(bench)

        let first = try store.startSession(at: t0)
        let e1 = try store.addEntry(bench, to: first)
        try store.addSet(SetValues(weight: 80, reps: 8), to: e1, at: t0)
        try store.finish(first)
        let second = try store.startSession(at: t0.addingTimeInterval(86_400))
        let e2 = try store.addEntry(bench, to: second)
        let pr = try store.addSet(SetValues(weight: 85, reps: 5), to: e2, at: t0.addingTimeInterval(86_400))
        try store.addSet(SetValues(weight: 85, reps: 4), to: e2, at: t0.addingTimeInterval(86_500))
        try store.finish(second)

        XCTAssertEqual(cache.badges(for: bench.id)[pr.id], [.weight])
        XCTAssertEqual(cache.countsBySession, [second.id: 1])
        XCTAssertEqual(cache.lastUsed(bench.id), second.startedAt)
        XCTAssertEqual(cache.summary(for: second), SessionSummary(sets: 2, volume: 85 * 9, duration: 100))
        XCTAssertEqual(cache.recentPRs(names: [bench.id: "Bench"]).map(\.id), [pr.id])

        // Adding a set updates only what changed.
        let version = cache.version
        let heavier = try store.addSet(SetValues(weight: 90, reps: 2), to: e2, at: t0.addingTimeInterval(86_600))
        XCTAssertGreaterThan(cache.version, version, "views reading the cache redraw")
        XCTAssertEqual(cache.badges(for: bench.id)[heavier.id], [.weight])
        XCTAssertEqual(cache.countsBySession, [second.id: 2])
        XCTAssertEqual(cache.summary(for: second).sets, 3)

        // Editing the older session removes the later PRs.
        try store.update(e1.orderedSets[0], to: SetValues(weight: 100, reps: 8))
        XCTAssertTrue(cache.badges(for: bench.id).isEmpty)
        XCTAssertEqual(cache.countsBySession, [:])

        // Deleting the older session, then undoing it.
        let snapshot = try store.deleteSession(first)
        XCTAssertEqual(cache.lastUsed(bench.id), second.startedAt)
        XCTAssertTrue(cache.badges(for: bench.id).isEmpty, "the first remaining session never has badges")
        try store.restoreSession(snapshot)
        XCTAssertTrue(cache.badges(for: bench.id).isEmpty)
        XCTAssertEqual(cache.summary(for: second).sets, 3)

        // Deleting a set.
        let set = e2.orderedSets[0]
        try store.delete(set, from: e2)
        XCTAssertEqual(cache.summary(for: second).sets, 2)
    }

    func testImportInvalidatesEverything() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let cache = PRCache.shared(for: context)
        XCTAssertEqual(cache.countsBySession, [:])
        DebugSeeder.seedLargeHistory(into: context, sessions: 30)
        XCTAssertEqual(cache.countsBySession, [:], "still cached until invalidated")
        cache.invalidateAll()
        XCTAssertFalse(cache.countsBySession.isEmpty)
    }

    /// The cache gives the same answers as computing from the model graph directly.
    func testCacheMatchesDirectComputation() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        DebugSeeder.seedLargeHistory(into: container.mainContext, sessions: 60)
        let context = ModelContext(container)
        let cache = PRCache(context: context)
        for exercise in try context.fetch(FetchDescriptor<Exercise>()) {
            XCTAssertEqual(cache.badges(for: exercise.id), PRDetector.badges(for: ProgressQueries.prInputs(for: exercise)))
            XCTAssertEqual(cache.lastUsed(exercise.id), exercise.lastUsed)
        }
        for session in try context.fetch(FetchDescriptor<WorkoutSession>()) {
            let summary = cache.summary(for: session)
            XCTAssertEqual(summary.sets, session.allSets.count)
            XCTAssertEqual(summary.volume, session.load, accuracy: 0.001)
            XCTAssertEqual(summary.duration, session.duration)
        }
    }
}

@MainActor
final class PRCacheBackgroundTests: XCTestCase {
    func testBackgroundBuildMatchesAndKeepsChangesMadeMeanwhile() async throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        DebugSeeder.seedLargeHistory(into: context, sessions: 60)
        let cache = PRCache(context: context)
        cache.warmUp()
        XCTAssertTrue(cache.isLoading)
        XCTAssertTrue(cache.countsBySession.isEmpty, "reads don't block while it loads")

        // A set logged while the build runs is still reflected once it lands.
        let session = try WorkoutStore(context: context).startSession()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "Bench Press" }!
        let entry = SessionExercise(order: 0, exercise: bench)
        session.entries.append(entry)
        let pr = WorkoutSet(order: 0, weight: 500, reps: 1)
        entry.sets.append(pr)
        cache.invalidate(exerciseID: bench.id, sessionID: session.id)

        let deadline = Date.now.addingTimeInterval(10)
        while cache.isLoading && Date.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(cache.isLoading)
        XCTAssertEqual(cache.badges(for: bench.id)[pr.id], [.weight])
        XCTAssertEqual(cache.summary(for: session).sets, 1)
        for exercise in try context.fetch(FetchDescriptor<Exercise>()) {
            XCTAssertEqual(cache.badges(for: exercise.id), PRDetector.badges(for: ProgressQueries.prInputs(for: exercise)))
        }
    }
}
