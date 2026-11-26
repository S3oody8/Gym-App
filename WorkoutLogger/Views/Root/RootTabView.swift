import SwiftData
import SwiftUI
import UIKit

/// Top-level tabs (Workouts / Exercises / Progress / Settings). The live workout opens full
/// screen over the tabs; minimised, a mini-bar shows above the tab bar. The screen is kept
/// awake while a workout is active.
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<WorkoutSession> { $0.finishedAt == nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var activeSessions: [WorkoutSession]
    @State private var selection: AppTab = DebugScenario.current?.initialTab ?? .workouts
    @State private var isWorkoutOpen = DebugScenario.current?.opensWorkout ?? false

    private var activeSession: WorkoutSession? { activeSessions.first }

    /// Shown above the tab bar on every tab while a workout is active and minimised,
    /// including after a relaunch with an unfinished workout.
    @ViewBuilder
    private var miniBar: some View {
        if let session = activeSession, !isWorkoutOpen {
            WorkoutMiniBar(session: session,
                           rest: RestTimerStore.shared.visiblePeriod(for: session.id)) { isWorkoutOpen = true }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Workouts", systemImage: "figure.strengthtraining.traditional", value: AppTab.workouts) {
                WorkoutsTabView { isWorkoutOpen = true }
                    .safeAreaInset(edge: .bottom, spacing: 0) { miniBar }
            }
            Tab("Exercises", systemImage: "dumbbell", value: AppTab.exercises) {
                ExercisesTabView()
                    .safeAreaInset(edge: .bottom, spacing: 0) { miniBar }
            }
            Tab("Progress", systemImage: "chart.xyaxis.line", value: AppTab.progress) {
                ProgressTabView()
                    .safeAreaInset(edge: .bottom, spacing: 0) { miniBar }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                SettingsTabView()
                    .safeAreaInset(edge: .bottom, spacing: 0) { miniBar }
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
        .onChange(of: scenePhase) { _, phase in
            // Make sure the pending "Rest over" alert (and Live Activity) match the rest
            // period whenever the app leaves or returns to the foreground.
            if phase != .inactive { RestTimerStore.shared.resync(activeSessionID: activeSession?.id) }
        }
        .onChange(of: activeSession == nil, initial: true) { _, none in
            UIApplication.shared.isIdleTimerDisabled = !none
            if none { isWorkoutOpen = false }
        }
    }
}

#Preview {
    let container = try! ModelSchema.makeContainer(inMemory: true)
    RootTabView()
        .modelContainer(container)
        .environment(PRCache.shared(for: container.mainContext))
}
