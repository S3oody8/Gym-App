import SwiftUI

/// The set pad: exercise name, Weight / Reps / RIR fields (empty shows "—"), ×2 and the
/// Working / Drop toggle, a large keypad and Save set (disabled until weight and reps are set).
struct SetEntrySheet: View {
    let request: SetEntryRequest
    let onSave: (SetValues) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.showDoubleButton)
    private var showDouble = SettingsKeys.defaultShowDoubleButton
    @State private var form: SetEntryForm
    @State private var contentHeight: CGFloat = 600

    init(request: SetEntryRequest, onSave: @escaping (SetValues) -> Void) {
        self.request = request
        self.onSave = onSave
        if let prefill = request.prefill, !request.isEditing {
            _form = State(initialValue: SetEntryForm(prefill: prefill))
        } else {
            _form = State(initialValue: SetEntryForm(initial: request.initial))
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            SetEntryFieldBox(title: "Weight (kg)", text: form.weightText, placeholder: "—",
                             isSelected: form.field == .weight) { form.select(.weight) }
            HStack(spacing: 8) {
                SetEntryFieldBox(title: "Reps", text: form.repsText,
                                 placeholder: form.repsHint.map(String.init) ?? "—",
                                 isSelected: form.field == .reps) { form.select(.reps) }
                SetEntryFieldBox(title: "RIR (0–5)", text: form.rirText, placeholder: "—",
                                 isSelected: form.field == .rir) { form.select(.rir) }
            }
            HStack(spacing: 10) {
                if showDouble {
                    Button {
                        form.toggleDouble()
                    } label: {
                        Text("×2")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(form.isDoubled ? Theme.onAccent : Theme.text)
                            .frame(width: 52, height: Theme.pillHeight)
                            .background(form.isDoubled ? Theme.accent : Theme.raised,
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .frame(minHeight: Theme.minTouch)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(form.isDoubled ? "Undo double weight" : "Double weight")
                    Text(form.isDoubled ? "Doubled. Saved as the total." : "One side? Tap ×2")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSubtle)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer(minLength: 0)
                }
                Picker("Set type", selection: $form.type) {
                    Text("Working").tag(SetType.working)
                    Text("Drop").tag(SetType.drop)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            NumericKeypadView(decimalEnabled: form.field == .weight) { form.press($0) }

            Button {
                guard let values = form.values else { return }
                onSave(values)
                dismiss()
            } label: {
                Text(request.isEditing ? "Save changes" : "Save set")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(form.values == nil ? Theme.textFaint : Theme.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(form.values == nil ? Theme.raised : Theme.accent,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(form.values == nil)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.surface)
    }

    private var header: some View {
        HStack {
            Text(request.exerciseName)
                .font(.headline)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            Spacer()
            Button("Cancel") { dismiss() }
                .foregroundStyle(Theme.textMuted)
        }
    }
}
