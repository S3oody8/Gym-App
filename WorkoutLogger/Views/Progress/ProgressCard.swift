import SwiftUI

/// Chart card: the current value (large), the change over the range in the accent colour,
/// the line chart, "Best set 82.5 × 8 · Sat 22/11" and the 1M–All range picker.
struct ProgressCard: View {
    let exercise: Exercise
    let metric: ProgressMetric
    @Binding var range: ProgressRange
    let onShowHistory: () -> Void

    var body: some View {
        let sessions = ProgressQueries.sessionInputs(for: exercise)
        let points = ProgressMath.points(metric, sessions: sessions, range: range)
        let best = ProgressSummary.bestSet(metric, sessions: sessions, range: range)
        GroupedCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(points.last.map { ProgressMath.label($0.value, metric: metric) } ?? "—")
                        .font(.largeTitle.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 8)
                    if let change = ProgressSummary.change(points) {
                        Text(ProgressSummary.changeLabel(change, metric: metric))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                }
                ProgressChartView(points: points, metric: metric)
                HStack {
                    if let best {
                        Text("Best set \(WeightFormatter.spaced(weight: best.values.weight, reps: best.values.reps)) · \(HistoryFormat.day(best.date))")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer(minLength: 8)
                    Button("All sets", action: onShowHistory)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.textMuted)
                        .frame(minHeight: Theme.minTouch)
                }
                Picker("Range", selection: $range) {
                    ForEach(ProgressRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
