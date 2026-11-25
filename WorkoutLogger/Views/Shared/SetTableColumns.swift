import SwiftUI

/// Column widths shared by the set table header and rows (scale with Dynamic Type).
struct SetTableColumns {
    @ScaledMetric(relativeTo: .body) var set: CGFloat = 36
    @ScaledMetric(relativeTo: .body) var kg: CGFloat = 72
    @ScaledMetric(relativeTo: .body) var reps: CGFloat = 52
}
