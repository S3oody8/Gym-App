import SwiftData
import SwiftUI

@main
struct WorkoutLoggerApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelSchema.makeContainer()
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
