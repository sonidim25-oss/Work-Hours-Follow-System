import SwiftUI

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: opacity
        )
    }
}

enum AppColors {
    static let background = Color(hex: 0x061321)
    static let backgroundElevated = Color(hex: 0x0E1B2E)
    static let surfaceDark = Color(hex: 0x16273F)
    static let surfaceCream = Color(hex: 0xF4EDE1)
    static let textLight = Color(hex: 0xF4EDE1)
    static let textDark = Color(hex: 0x142033)
    static let secondary = Color(hex: 0x8D94A1)
    static let gold = Color(hex: 0xC9A66B)
    static let accent = Color(hex: 0xD8332A)
}
