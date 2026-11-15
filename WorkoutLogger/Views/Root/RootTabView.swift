import SwiftData
import SwiftUI
import UIKit

/// Top-level tabs. Shows a "Resume workout" banner on launch if a workout was left active,
/// and keeps the screen awake while a workout is active.
struct RootTabView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.finishedAt == nil })
    private var activeSessions: [WorkoutSession]
    @State private var selection: AppTab = DebugScenario.current?.initialTab ?? .workout
    @State private var didCheckResume = false
    @State private var showResumeBanner = false

    private var hasActiveWorkout: Bool { !activeSessions.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            if showResumeBanner && hasActiveWorkout {
                ResumeWorkoutBanner(startedAt: activeSessions.first?.startedAt) {
                    selection = .workout
                    showResumeBanner = false
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
        .animation(.default, value: showResumeBanner)
        .onAppear {
            guard !didCheckResume else { return }
            didCheckResume = true
            showResumeBanner = hasActiveWorkout
        }
        .onChange(of: hasActiveWorkout, initial: true) { _, active in
            UIApplication.shared.isIdleTimerDisabled = active
            if !active { showResumeBanner = false }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
