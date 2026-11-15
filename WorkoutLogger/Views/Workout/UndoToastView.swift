import SwiftUI

/// Toast showing the last action with an Undo button.
struct UndoToastView: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .font(.subheadline.weight(.medium))
            Spacer()
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
        }
        .padding(.horizontal, 16)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4, y: 2)
    }
}
