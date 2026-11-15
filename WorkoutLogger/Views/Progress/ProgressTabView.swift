import SwiftData
import SwiftUI

/// Progress tab: training calendar, then exercises with history (tap for graph + PRs).
struct ProgressTabView: View {
    @Environment(\.modelContext) private var context
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

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
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
                Section("Exercises") {
                    let tracked = exercises.filter(\.hasHistory)
                    if tracked.isEmpty {
                        Text("Log a workout to see graphs and PRs.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(tracked) { exercise in
                        NavigationLink(value: ProgressRoute.exercise(exercise)) {
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text(exercise.equipment.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle("Progress")
            .navigationDestination(for: ProgressRoute.self) { route in
                switch route {
                case .exercise(let exercise):
                    ExerciseProgressView(exercise: exercise)
                case .session(let session):
                    SessionDetailView(session: session, context: context) {
                        deleteAfterPop = session
                        path.removeAll()
                    }
                }
            }
            .confirmationDialog("Open workout", isPresented: Binding(
                get: { !dayChoices.isEmpty }, set: { if !$0 { dayChoices = [] } }
            )) {
                ForEach(dayChoices) { session in
                    Button("\(SessionMetrics.title(name: session.name)) · \(session.startedAt.formatted(date: .omitted, time: .shortened))") {
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
}

#Preview {
    ProgressTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
