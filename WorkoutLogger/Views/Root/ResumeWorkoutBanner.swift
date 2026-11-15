import SwiftUI

/// Shown on relaunch when a workout was still active.
struct ResumeWorkoutBanner: View {
    let startedAt: Date?
    let onResume: () -> Void

    var body: some View {
        Button(action: onResume) {
            HStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume workout")
                        .font(.headline)
                    if let startedAt {
                        Text("Started \(startedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .opacity(0.85)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the active workout")
    }
}
