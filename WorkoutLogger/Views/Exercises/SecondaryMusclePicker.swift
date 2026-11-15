import SwiftUI

/// Multi-select list of secondary muscles (the primary muscle is excluded).
struct SecondaryMusclePicker: View {
    @Binding var selection: Set<MuscleGroup>
    let primary: MuscleGroup

    var body: some View {
        List {
            ForEach(MuscleGroup.allCases.filter { $0 != primary }) { muscle in
                Button {
                    if selection.contains(muscle) {
                        selection.remove(muscle)
                    } else {
                        selection.insert(muscle)
                    }
                } label: {
                    HStack {
                        Text(muscle.rawValue)
                        Spacer()
                        if selection.contains(muscle) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .tint(.primary)
            }
        }
        .navigationTitle("Secondary Muscles")
        .navigationBarTitleDisplayMode(.inline)
    }
}
