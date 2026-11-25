import SwiftData
import SwiftUI
import UIKit

/// Top-level tabs (Workouts / Exercises / Progress / Settings). The live workout opens full
/// screen over the tabs. The screen is kept awake while a workout is active.
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WorkoutSession> { $0.finishedAt == nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var activeSessions: [WorkoutSession]
    @State private var selection: AppTab = DebugScenario.current?.initialTab ?? .workouts
    @State private var isWorkoutOpen = DebugScenario.current?.opensWorkout ?? false

    private var activeSession: WorkoutSession? { activeSessions.first }

    var body: some View {
        VStack(spacing: 0) {
            if let session = activeSession, !isWorkoutOpen {
                ResumeWorkoutBanner(startedAt: session.startedAt) { isWorkoutOpen = true }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            TabView(selection: $selection) {
                Tab("Workouts", systemImage: "figure.strengthtraining.traditional", value: AppTab.workouts) {
                    WorkoutsTabView { isWorkoutOpen = true }
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
        .fullScreenCover(isPresented: Binding(
            get: { isWorkoutOpen && activeSession != nil },
            set: { isWorkoutOpen = $0 }
        )) {
            if let session = activeSession {
                NavigationStack {
                    ActiveWorkoutView(session: session, context: context) { isWorkoutOpen = false }
                }
                .id(session.id)
            }
        }
        .background(Theme.background)
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .task { await DebugSeeder.importShrugIfNeeded(into: context) }
        .onChange(of: activeSession == nil, initial: true) { _, none in
            UIApplication.shared.isIdleTimerDisabled = !none
            if none { isWorkoutOpen = false }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
