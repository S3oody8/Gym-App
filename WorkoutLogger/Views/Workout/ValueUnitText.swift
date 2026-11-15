import SwiftUI

/// A large number followed by a small grey unit, e.g. "82.5 kg".
struct ValueUnitText: View {
    let value: String
    let unit: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.body.weight(.semibold).monospacedDigit())
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
