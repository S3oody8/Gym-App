import Foundation

/// Formats kg values for display without trailing zeros.
enum WeightFormatter {
    private static let style = FloatingPointFormatStyle<Double>.number
        .precision(.fractionLength(0...2))
        .grouping(.never)
        .locale(Locale(identifier: "en_US_POSIX"))

    /// 2.5 → "2.5", 80 → "80", 1.25 → "1.25".
    static func string(_ kg: Double) -> String {
        kg.formatted(style)
    }

    /// Compact "weight×reps", e.g. "80×8".
    static func compact(weight: Double, reps: Int) -> String {
        "\(string(weight))×\(reps)"
    }
}
