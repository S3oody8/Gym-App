import SwiftUI

/// Pop-up for adding or editing a set, typed on a large custom keypad.
struct SetEntrySheet: View {
    let request: SetEntryRequest
    let onSave: (SetValues) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var form: SetEntryForm

    init(request: SetEntryRequest, onSave: @escaping (SetValues) -> Void) {
        self.request = request
        self.onSave = onSave
        _form = State(initialValue: SetEntryForm(initial: request.initial))
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            HStack(spacing: 8) {
                stepButton(up: false)
                SetEntryFieldBox(title: "Weight (kg)", text: form.weightText, placeholder: "0",
                                 isSelected: form.field == .weight) { form.select(.weight) }
                stepButton(up: true)
            }
            HStack(spacing: 8) {
                SetEntryFieldBox(title: "Reps", text: form.repsText, placeholder: "0",
                                 isSelected: form.field == .reps) { form.select(.reps) }
                SetEntryFieldBox(title: "RIR (0–5)", text: form.rirText, placeholder: "–",
                                 isSelected: form.field == .rir) { form.select(.rir) }
            }
            Picker("Set type", selection: $form.type) {
                Text("Working").tag(SetType.working)
                Text("Drop set").tag(SetType.drop)
            }
            .pickerStyle(.segmented)

            Spacer(minLength: 0)

            NumericKeypadView(decimalEnabled: form.field == .weight) { form.press($0) }

            Button {
                guard let values = form.values else { return }
                onSave(values)
                dismiss()
            } label: {
                Text(request.isEditing ? "Save Changes" : "Save Set")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .disabled(form.values == nil)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Text(request.exerciseName)
                .font(.headline)
                .lineLimit(2)
            Spacer()
            Button("Cancel") { dismiss() }
        }
    }

    private func stepButton(up: Bool) -> some View {
        Button {
            form.stepWeight(by: request.increment, up: up)
        } label: {
            Image(systemName: up ? "plus" : "minus")
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 64)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(up ? "Increase weight by \(WeightFormatter.string(request.increment)) kg"
                               : "Decrease weight by \(WeightFormatter.string(request.increment)) kg")
    }
}
