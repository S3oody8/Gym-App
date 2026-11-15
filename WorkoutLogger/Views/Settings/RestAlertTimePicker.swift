import SwiftUI

/// Minutes + seconds wheels (15 s steps), constrained to 0:30–10:00.
struct RestAlertTimePicker: View {
    @Binding var totalSeconds: Int

    private var minutes: Binding<Int> {
        Binding(
            get: { totalSeconds / 60 },
            set: { totalSeconds = RestTimerMath.alertSeconds(minutes: $0, seconds: totalSeconds % 60) }
        )
    }

    private var seconds: Binding<Int> {
        Binding(
            get: { totalSeconds % 60 },
            set: { totalSeconds = RestTimerMath.alertSeconds(minutes: totalSeconds / 60, seconds: $0) }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Minutes", selection: minutes) {
                ForEach(0...10, id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.wheel)
            Picker("Seconds", selection: seconds) {
                ForEach([0, 15, 30, 45], id: \.self) { Text(String(format: "%02d s", $0)).tag($0) }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 150)
    }
}
