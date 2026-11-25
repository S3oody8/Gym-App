import SwiftUI

/// A settings row with a title, an optional detail line and a switch in the accent colour.
struct SwitchRow: View {
    let title: String
    var detail: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(Theme.text)
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSubtle)
                }
            }
        }
        .tint(Theme.accent)
        .frame(minHeight: Theme.minTouch)
    }
}
