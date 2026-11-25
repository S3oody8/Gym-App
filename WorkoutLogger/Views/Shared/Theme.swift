import SwiftUI

/// Colour tokens and sizes from SPEC §6. The app is dark only.
enum Theme {
    static let background = Color(hex: 0x0E0F11)
    static let surface = Color(hex: 0x16181B)
    static let surfaceAlt = Color(hex: 0x1A1C20)
    static let raised = Color(hex: 0x24272C)
    static let hairline = Color(hex: 0x22252A)
    static let border = Color(hex: 0x2E3238)
    static let text = Color(hex: 0xF2F3F5)
    static let textMuted = Color(hex: 0x9BA1A9)
    static let textSubtle = Color(hex: 0x8A9099)
    static let textFaint = Color(hex: 0x6B717A)
    /// "Do this now" only: Start, Finish, Save, current exercise, rest time, selected tab, PR.
    static let accent = Color(hex: 0xC6F432)
    static let onAccent = Color(hex: 0x0E0F11)
    static let destructive = Color(hex: 0xE5484D)

    static let cardRadius: CGFloat = 16
    static let primaryButtonHeight: CGFloat = 48
    static let pillHeight: CGFloat = 34
    static let minTouch: CGFloat = 44
}
