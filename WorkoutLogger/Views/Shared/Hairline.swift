import SwiftUI

/// 1 px separator in the hairline colour.
struct Hairline: View {
    @Environment(\.displayScale) private var scale

    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1 / scale)
    }
}
