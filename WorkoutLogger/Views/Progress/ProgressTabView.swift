import SwiftData
import SwiftUI

/// Progress tab: an exercise picker pill, the metric control, a chart card (current value,
/// change over the range, line chart, best set, range picker), RECENT PRs and the training
/// calendar (tap a day to open that session).
struct ProgressTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(PRCache.self) private var prCache
    @Query(
        filter: #Predicate<WorkoutSession> { $0.finishedAt != nil },
        sort: \WorkoutSession.startedAt, order: .reverse
    )
    private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    private let calendar = CalendarMath.mondayCalendar()
    @State private var month = CalendarMath.monthStart(.now, calendar: CalendarMath.mondayCalendar())
    @State private var path: [ProgressRoute] = []
    @State private var dayChoices: [WorkoutSession] = []
    @State private var history = HistoryViewModel()
    @State private var deleteAfterPop: WorkoutSession?
    @State private var selectedID: UUID?
    @State private var metric: ProgressMetric = DebugScenario.initialMetric ?? .e1RM
    @State private var range: ProgressRange = .threeMonths

    /// Exercises with history, most recently used first.
    private var tracked: [Exercise] {
        ExerciseOrdering.recentFirst(exercises.filter(\.hasHistory), lastUsed: { prCache.lastUsed($0.id) },
                                     name: \.name)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let tracked = tracked
                    if let exercise = tracked.first(where: { $0.id == selectedID }) ?? tracked.first {
                        exercisePicker(tracked, selected: exercise)
                        Picker("Metric", selection: $metric) {
                            Text("Estimated 1RM").tag(ProgressMetric.e1RM)
                            Text("Top set").tag(ProgressMetric.topSet)
                            Text("Volume").tag(ProgressMetric.volume)
                        }
                        .pickerStyle(.segmented)
                        ProgressCard(exercise: exercise, metric: metric, range: $range) {
                            path.append(.exercise(exercise))
                        }
                    } else {
                        Text("Log a workout to see graphs and PRs.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSubtle)
                    }
                    recentPRs
                    GroupedCard(padding: 12) {
                        TrainingCalendarView(
                            month: $month,
                            sessionsByDay: CalendarMath.sessionsByDay(sessions, date: \.startedAt, calendar: calendar),
                            calendar: calendar
                        ) { daySessions in
                            if daySessions.count == 1 {
                                path.append(.session(daySessions[0]))
                            } else {
                                dayChoices = daySessions
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle("Progress")
            .navigationDestination(for: ProgressRoute.self) { route in
                switch route {
                case .exercise(let exercise):
                    ExerciseProgressView(exercise: exercise)
                case .session(let session):
                    PastWorkoutView(session: session) {
                        deleteAfterPop = session
                        path.removeAll()
                    }
                }
            }
            .confirmationDialog("Open workout", isPresented: Binding(
                get: { !dayChoices.isEmpty }, set: { if !$0 { dayChoices = [] } }
            )) {
                ForEach(dayChoices) { session in
                    Button("\(SessionMetrics.title(name: session.name)) · \(HistoryFormat.time(session.startedAt))") {
                        path.append(.session(session))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if history.deletedSnapshot != nil {
                    UndoToastView(message: "Workout deleted") { history.undoDelete(in: context) }
                        .padding()
                }
            }
            .onChange(of: path) { _, newPath in
                if newPath.isEmpty, let session = deleteAfterPop {
                    deleteAfterPop = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        history.delete(session, in: context)
                    }
                }
            }
        }
    }

    private func exercisePicker(_ tracked: [Exercise], selected: Exercise) -> some View {
        Menu {
            ForEach(tracked) { exercise in
                Button(exercise.name) { selectedID = exercise.id }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selected.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 14)
            .frame(minHeight: Theme.pillHeight)
            .background(Theme.raised, in: Capsule())
            .frame(minHeight: Theme.minTouch)
        }
        .accessibilityLabel("Exercise: \(selected.name)")
    }

    @ViewBuilder
    private var recentPRs: some View {
        let prs = prCache.recentPRs(names: Dictionary(exercises.map { ($0.id, $0.name) },
                                                      uniquingKeysWith: { a, _ in a }))
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Recent PRs")
            GroupedCard {
                if prs.isEmpty {
                    Text("PRs you set will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSubtle)
                        .padding(16)
                }
                ForEach(Array(prs.enumerated()), id: \.element.id) { index, pr in
                    if index > 0 { Hairline().padding(.leading, 16) }
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pr.exerciseName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                            Text(HistoryFormat.day(pr.date))
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Theme.textSubtle)
                        }
                        Spacer(minLength: 8)
                        Text(WeightFormatter.spaced(weight: pr.values.weight, reps: pr.values.reps))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 52)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelSchema.makeContainer(inMemory: true)
    ProgressTabView()
        .modelContainer(container)
        .environment(PRCache.shared(for: container.mainContext))
}
