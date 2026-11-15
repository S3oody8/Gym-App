import SwiftData
import SwiftUI

@main
struct WorkoutLoggerApp: App {
    let container: ModelContainer

    init() {
        do {
            if let scenario = DebugScenario.current {
                container = try ModelSchema.makeContainer(inMemory: true)
                DebugSeeder.seed(scenario, into: container.mainContext)
            } else {
                container = try ModelSchema.makeContainer()
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
