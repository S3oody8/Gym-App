import SwiftData
import XCTest
@testable import WorkoutLogger

/// Timings on about the user's real history size: 300 workouts, 15 exercises, 6,000 sets.
/// Each measurement uses a fresh `ModelContext`, so objects are fetched from the store rather
/// than already in memory. Targets (simulator): full cache build < 150 ms, one exercise < 10 ms.
@MainActor
final class PerformanceTests: XCTestCase {
    private var container: ModelContainer!
    private var firstExerciseID = UUID()

    override func setUp() async throws {
        container = try ModelSchema.makeContainer(inMemory: true)
        DebugSeeder.seedLargeHistory(into: container.mainContext)
        firstExerciseID = try container.mainContext.fetch(FetchDescriptor<Exercise>()).first!.id
    }

    func testSeedSize() throws {
        let context = ModelContext(container)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutSession>()), 300)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 15)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutSet>()), 6_000)
    }

    /// Everything the Workouts, Exercises and Progress tabs need, from cold.
    func testFullCacheBuild() {
        measure {
            let context = ModelContext(container) // the cache holds its context weakly
            let cache = PRCache(context: context)
            XCTAssertFalse(cache.countsBySession.isEmpty)
            XCTAssertNotNil(cache.lastUsed(firstExerciseID))
        }
    }

    /// The history tab: PR counts plus every row summary, from cold.
    func testHistoryPRCounts() throws {
        let sessions = try ModelContext(container).fetch(FetchDescriptor<WorkoutSession>())
        measure {
            let context = ModelContext(container)
            let cache = PRCache(context: context)
            let counts = cache.countsBySession
            let summaries = try! context.fetch(FetchDescriptor<WorkoutSession>()).map { cache.summary(for: $0) }
            XCTAssertFalse(counts.isEmpty)
            XCTAssertEqual(summaries.count, sessions.count)
        }
    }

    /// One exercise's badges after it changed (what logging a set costs).
    func testOneExerciseBadgesAfterInvalidation() throws {
        let context = ModelContext(container)
        let cache = PRCache(context: context)
        _ = cache.countsBySession
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "Bench Press" }!
        measure {
            cache.invalidate(exerciseID: bench.id)
            XCTAssertFalse(cache.badges(for: bench.id).isEmpty)
            _ = cache.countsBySession
        }
    }

    /// Reading a warm cache (what every redraw costs).
    func testWarmReads() throws {
        let context = ModelContext(container)
        let cache = PRCache(context: context)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        _ = cache.countsBySession
        measure {
            for _ in 0..<100 {
                _ = cache.countsBySession
                for exercise in exercises { _ = cache.badges(for: exercise.id) }
            }
        }
    }
}
