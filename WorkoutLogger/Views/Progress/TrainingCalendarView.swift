import SwiftUI

/// Month calendar (Monday–Sunday weeks). Training days are filled circles; tap one to open it.
struct TrainingCalendarView: View {
    @Binding var month: Date
    let sessionsByDay: [Date: [WorkoutSession]]
    let calendar: Calendar
    let onSelectDay: ([WorkoutSession]) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        let cells = CalendarMath.monthGrid(for: month, calendar: calendar)
        let today = calendar.startOfDay(for: .now)
        VStack(spacing: 8) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous month")
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next month")
            }
            .buttonStyle(.borderless)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(CalendarMath.weekdaySymbols(calendar: calendar).enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day, isToday: day == today)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }

            let count = trainingDaysInMonth(cells)
            Text("\(count) training day\(count == 1 ? "" : "s") this month")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func dayCell(_ day: Date, isToday: Bool) -> some View {
        let sessions = sessionsByDay[day] ?? []
        let trained = !sessions.isEmpty
        return Button {
            if trained { onSelectDay(sessions) }
        } label: {
            Text("\(calendar.component(.day, from: day))")
                .font(.subheadline.monospacedDigit().weight(trained ? .semibold : .regular))
                .foregroundStyle(trained ? Theme.onAccent : (isToday ? Theme.accent : Theme.text))
                .frame(width: 34, height: 34)
                .background {
                    if trained {
                        Circle().fill(Theme.accent)
                    } else if isToday {
                        Circle().strokeBorder(Theme.accent, lineWidth: 1.5)
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(trained)
        .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted))\(trained ? ", trained" : "")")
    }

    private func trainingDaysInMonth(_ cells: [Date?]) -> Int {
        cells.compactMap { $0 }.filter { sessionsByDay[$0] != nil }.count
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) {
            month = CalendarMath.monthStart(next, calendar: calendar)
        }
    }
}
