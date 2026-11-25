import SwiftData
import SwiftUI
import UserNotifications

@main
struct WorkoutLoggerApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    /// v1.0 scheduled a repeating "Back up your workouts" notification; the weekly automatic
    /// backup replaces it.
    private static let oldBackupReminderID = "backup-reminder"

    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
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
                .task {
                    UNUserNotificationCenter.current()
                        .removePendingNotificationRequests(withIdentifiers: [Self.oldBackupReminderID])
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active, DebugScenario.current == nil else { return }
            AutoBackup.runIfDue(context: container.mainContext)
        }
    }
}
