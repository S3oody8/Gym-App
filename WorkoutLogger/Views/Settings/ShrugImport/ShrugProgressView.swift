import SwiftUI

/// Progress bar while sets are written in batches.
struct ShrugProgressView: View {
    let done: Int
    let total: Int

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(done), total: Double(max(total, 1)))
                .progressViewStyle(.linear)
            Text("Importing… \(done.formatted()) of \(total.formatted()) sets")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text("Keep the app open until this finishes.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxHeight: .infinity)
    }
}
