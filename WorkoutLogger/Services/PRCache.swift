import Foundation
import Observation
import SwiftData

/// Caches PR badges, PR counts per session, RECENT PRs, last-used dates and history row
/// summaries so no screen recomputes them over the whole history while drawing.
///
/// Results are computed lazily on first read and kept until invalidated. `WorkoutStore`
/// invalidates the affected exercise(s) and session after every set / entry / session change;
/// imports, JSON restore and the debug seed call `invalidateAll()`. Reading registers a
/// dependency on `version`, so views redraw after an invalidation and read the fresh values.
///
/// One cache per `ModelContext` (`shared(for:)`); the app passes the main context's cache
/// through the environment. At launch (`warmUp()`) the full build runs on a background
/// `PRCacheBuilder` so the first frame never waits for it; screens show no PR marks for that
/// moment and redraw when the results arrive.
@MainActor
@Observable
final class PRCache {
    /// Bumped on every invalidation; the only observed property.
    private(set) var version = 0

    @ObservationIgnored private weak var context: ModelContext?
    @ObservationIgnored private var indexes: [UUID: ExercisePRIndex] = [:]
    @ObservationIgnored private var stale: Set<UUID> = []
    @ObservationIgnored private var isBuilt = false
    @ObservationIgnored private var counts: [UUID: Int]?
    @ObservationIgnored private var summaries: [UUID: SessionSummary] = [:]
    /// Set by `warmUp()`: full builds run in the background from then on.
    @ObservationIgnored private var buildsInBackground = false
    @ObservationIgnored private var loading: Task<Void, Never>?
    /// Invalidations that arrive while a background build runs are applied on top of it.
    @ObservationIgnored private var staleDuringLoad: Set<UUID> = []
    @ObservationIgnored private var sessionsDuringLoad: Set<UUID> = []

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Registry

    private static var caches: [ObjectIdentifier: PRCache] = [:]

    /// The cache for this context (created on first use).
    static func shared(for context: ModelContext) -> PRCache {
        let key = ObjectIdentifier(context)
        if let cache = caches[key], cache.context === context { return cache }
        caches = caches.filter { $0.value.context != nil }
        let cache = PRCache(context: context)
        caches[key] = cache
        return cache
    }

    // MARK: Reads

    /// PR badges for every set of the exercise, by set id.
    func badges(for exerciseID: UUID?) -> [UUID: PRBadges] {
        guard let exerciseID else { return [:] }
        return index(for: exerciseID).badges
    }

    /// Number of PR sets per session id, over every exercise.
    var countsBySession: [UUID: Int] {
        _ = version
        if let counts { return counts }
        ensureAll()
        var result: [UUID: Int] = [:]
        for index in indexes.values {
            result.merge(index.prCountsBySession, uniquingKeysWith: +)
        }
        counts = result
        return result
    }

    /// Start of the most recent session with at least one set of the exercise.
    func lastUsed(_ exerciseID: UUID) -> Date? {
        _ = version
        ensureAll()
        return indexes[exerciseID]?.lastUsed
    }

    /// RECENT PRs, newest first. `names` maps exercise ids to their current names; exercises
    /// missing from it are left out.
    func recentPRs(names: [UUID: String], limit: Int = 10) -> [RecentPR] {
        _ = version
        ensureAll()
        let all = indexes.flatMap { id, index -> [RecentPR] in
            guard let name = names[id] else { return [] }
            return index.prSets.map { RecentPR(id: $0.id, exerciseName: name, date: $0.date, values: $0.values) }
        }
        return ProgressSummary.newestFirst(all, limit: limit)
    }

    /// Sets, volume and duration for a history row.
    func summary(for session: WorkoutSession) -> SessionSummary {
        _ = version
        if !isBuilt { ensureAll() }
        if let summary = summaries[session.id] { return summary }
        let sets = session.allSets
        let summary = SessionSummary(values: sets.map(\.values), times: sets.map(\.loggedAt))
        summaries[session.id] = summary
        return summary
    }

    // MARK: Invalidation

    /// Call after any change to the exercise's sets (or the sessions they belong to).
    func invalidate(exerciseID: UUID?, sessionID: UUID? = nil) {
        if let exerciseID { stale.insert(exerciseID) }
        if let sessionID { summaries[sessionID] = nil }
        if loading != nil {
            if let exerciseID { staleDuringLoad.insert(exerciseID) }
            if let sessionID { sessionsDuringLoad.insert(sessionID) }
        }
        counts = nil
        version &+= 1
    }

    /// Every exercise in the session plus the session itself (delete, restore, move).
    func invalidate(session: WorkoutSession) {
        for entry in session.entries {
            if let id = entry.exercise?.id { invalidate(exerciseID: id) }
        }
        invalidate(exerciseID: nil, sessionID: session.id)
    }

    /// After an import, a JSON restore or the debug seed.
    func invalidateAll() {
        loading?.cancel()
        loading = nil
        indexes = [:]
        stale = []
        isBuilt = false
        counts = nil
        summaries = [:]
        version &+= 1
        if buildsInBackground { startBackgroundBuild() }
    }

    // MARK: Background build

    /// True while the background build runs.
    var isLoading: Bool { loading != nil }

    /// Starts the full build on a background actor (called once at launch).
    func warmUp() {
        buildsInBackground = true
        if !isBuilt { startBackgroundBuild() }
    }

    private func startBackgroundBuild() {
        guard loading == nil, let container = context?.container else { return }
        staleDuringLoad = []
        sessionsDuringLoad = []
        loading = Task { [weak self] in
            let snapshot = await PRCacheBuilder(modelContainer: container).snapshot()
            guard !Task.isCancelled else { return }
            self?.apply(snapshot)
        }
    }

    private func apply(_ snapshot: Snapshot) {
        loading = nil
        indexes = snapshot.indexes
        summaries = snapshot.summaries
        // Changes made while it ran (unsaved ones are invisible to the background context).
        stale = staleDuringLoad
        for id in sessionsDuringLoad { summaries[id] = nil }
        staleDuringLoad = []
        sessionsDuringLoad = []
        counts = nil
        isBuilt = true
        version &+= 1
    }

    // MARK: Building

    /// The exercise's index, rebuilt with one small fetch when missing or stale.
    private func index(for exerciseID: UUID) -> ExercisePRIndex {
        _ = version
        if !stale.contains(exerciseID), let index = indexes[exerciseID] { return index }
        let index = ExercisePRIndex(sets: fetchInputs(exerciseID: exerciseID))
        indexes[exerciseID] = index
        stale.remove(exerciseID)
        return index
    }

    /// Builds everything once with a single fetch, then refreshes stale exercises one by one.
    /// While a background build is running, reads return what is cached so far.
    private func ensureAll() {
        if !isBuilt {
            if loading != nil { return }
            if buildsInBackground {
                startBackgroundBuild()
                return
            }
            if let context { apply(Self.makeSnapshot(context: context)) }
            return
        }
        for id in stale {
            indexes[id] = ExercisePRIndex(sets: fetchInputs(exerciseID: id))
        }
        stale = []
    }

    /// Every exercise's index and every session's summary.
    struct Snapshot: Sendable {
        var indexes: [UUID: ExercisePRIndex]
        var summaries: [UUID: SessionSummary]
    }

    /// One fetch of every session entry with its sets, session and exercise prefetched (the
    /// fastest of the shapes measured: ~120 ms for 6,000 sets on the simulator, ~150 ms in all).
    nonisolated static func makeSnapshot(context: ModelContext) -> Snapshot {
        var descriptor = FetchDescriptor<SessionExercise>()
        descriptor.relationshipKeyPathsForPrefetching = [\.sets, \.session, \.exercise]
        let entries = (try? context.fetch(descriptor)) ?? []
        var byExercise: [UUID: [PRInputSet]] = [:]
        var bySession: [UUID: (values: [SetValues], times: [Date])] = [:]
        for entry in entries {
            guard let session = entry.session else { continue }
            let sessionID = session.id, start = session.startedAt
            let sets = entry.sets
            guard !sets.isEmpty else { continue }
            let values = sets.map(\.values)
            bySession[sessionID, default: ([], [])].values.append(contentsOf: values)
            bySession[sessionID, default: ([], [])].times.append(contentsOf: sets.map(\.loggedAt))
            guard let exerciseID = entry.exercise?.id else { continue }
            let base = entry.order * 10_000
            byExercise[exerciseID, default: []].append(contentsOf: zip(sets, values).map { set, values in
                PRInputSet(id: set.id, sessionID: sessionID, sessionStart: start, order: base + set.order, values: values)
            })
        }
        return Snapshot(indexes: byExercise.mapValues { ExercisePRIndex(sets: $0) },
                        summaries: bySession.mapValues { SessionSummary(values: $0.values, times: $0.times) })
    }

    /// One exercise's sets: its session entries by predicate with their sets and sessions
    /// prefetched (~8 ms for 400 sets on the simulator; walking the relationships or fetching
    /// the sets through two relationships measured 15–45 ms).
    private func fetchInputs(exerciseID: UUID) -> [PRInputSet] {
        guard let context else { return [] }
        var descriptor = FetchDescriptor<SessionExercise>(predicate: #Predicate { $0.exercise?.id == exerciseID })
        descriptor.relationshipKeyPathsForPrefetching = [\.sets, \.session]
        let entries = (try? context.fetch(descriptor)) ?? []
        return entries.flatMap { entry -> [PRInputSet] in
            guard let session = entry.session else { return [] }
            let sessionID = session.id, start = session.startedAt
            return entry.sets.map { set in
                PRInputSet(id: set.id, sessionID: sessionID, sessionStart: start,
                           order: entry.order * 10_000 + set.order, values: set.values)
            }
        }
    }
}
