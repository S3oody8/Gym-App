import SwiftData
import SwiftUI
import UIKit

/// Top-level tabs. While a workout is active, a "Resume workout" banner shows on every tab
/// except Workout, and the screen is kept awake.
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WorkoutSession> { $0.finishedAt == nil })
    private var activeSessions: [WorkoutSession]
    @State private var selection: AppTab = DebugScenario.current?.initialTab ?? .workout

    private var hasActiveWorkout: Bool { !activeSessions.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            if hasActiveWorkout && selection != .workout {
                ResumeWorkoutBanner(startedAt: activeSessions.first?.startedAt) {
                    selection = .workout
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            TabView(selection: $selection) {
                Tab("Workout", systemImage: "figure.strengthtraining.traditional", value: AppTab.workout) {
                    WorkoutTabView()
                }
                Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                    HistoryTabView()
                }
                Tab("Exercises", systemImage: "dumbbell", value: AppTab.exercises) {
                    ExercisesTabView()
                }
                Tab("Progress", systemImage: "chart.xyaxis.line", value: AppTab.progress) {
                    ProgressTabView()
                }
                Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                    SettingsTabView()
                }
            }
        }
        .animation(.default, value: selection)
        .task { await DebugSeeder.importShrugIfNeeded(into: context) }
        .onChange(of: hasActiveWorkout, initial: true) { _, active in
            UIApplication.shared.isIdleTimerDisabled = active
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
