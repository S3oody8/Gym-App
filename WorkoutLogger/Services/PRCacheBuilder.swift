import Foundation
import SwiftData

/// Runs `PRCache`'s full build off the main thread, with its own `ModelContext`.
@ModelActor
actor PRCacheBuilder {
    func snapshot() -> PRCache.Snapshot {
        PRCache.makeSnapshot(context: modelContext)
    }
}
