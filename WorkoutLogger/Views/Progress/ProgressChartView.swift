import Charts
import SwiftUI

/// Line chart of one metric per session.
struct ProgressChartView: View {
    let points: [ProgressPoint]
    let metric: ProgressMetric

    var body: some View {
        if points.isEmpty {
            ContentUnavailableView("No Data", systemImage: "chart.xyaxis.line",
                                   description: Text("No sets in this range."))
                .frame(height: 200)
        } else {
            Chart(points) { point in
                LineMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value))
                    .symbolSize(30)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                }
            }
            .frame(height: 200)
            .accessibilityLabel("\(metric.rawValue) over time")
        }
    }
}
