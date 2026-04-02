import SwiftUI

// MARK: - Color Hex Init (einmalig, sauber)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - IPM Farben (alle programmatisch, kein Assets.xcassets nötig)
enum IPMColors {
    // Dark Mode Hintergründe
    static let darkBackground    = Color(hex: "#1C1008")
    static let darkCard          = Color(hex: "#2A1E0F")
    static let darkCardSecondary = Color(hex: "#3A2A18")
    static let darkTextPrimary   = Color(hex: "#FFF8F0")

    // Light Mode Hintergründe
    static let lightBackground    = Color(hex: "#FFF8F0")
    static let lightCard          = Color(hex: "#F0E6D3")
    static let lightCardSecondary = Color(hex: "#E8D5B7")
    static let lightTextPrimary   = Color(hex: "#1C1008")

    // Brand
    static let green     = Color(hex: "#558B2F")
    static let greenDark = Color(hex: "#4E7A27")
    static let greenLight = Color(hex: "#A5D6A7")
    static let brown     = Color(hex: "#4E342E")
    static let brownMid  = Color(hex: "#8D6E63")

    // Status
    static let ok       = Color(hex: "#558B2F")
    static let okLight  = Color(hex: "#A5D6A7")
    static let warning  = Color(hex: "#E65100")
    static let critical = Color(hex: "#B71C1C")
    static let befund   = Color(hex: "#F9A825")
}

// MARK: - Adaptive Colors (Dark / Light automatisch)
enum AdaptiveColor {
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? IPMColors.darkBackground : IPMColors.lightBackground
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? IPMColors.darkCard : IPMColors.lightCard
    }
    static func cardSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? IPMColors.darkCardSecondary : IPMColors.lightCardSecondary
    }
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? IPMColors.darkTextPrimary : IPMColors.lightTextPrimary
    }
}

// MARK: - Card Modifier
struct IPMCardModifier: ViewModifier {
    @Environment(\.colorScheme) var scheme
    let padding: CGFloat
    let cornerRadius: CGFloat
    let secondary: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(secondary ? AdaptiveColor.cardSecondary(scheme) : AdaptiveColor.card(scheme))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func ipmCard(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        modifier(IPMCardModifier(padding: padding, cornerRadius: cornerRadius, secondary: false))
    }
    func ipmCardSecondary(padding: CGFloat = 12, cornerRadius: CGFloat = 12) -> some View {
        modifier(IPMCardModifier(padding: padding, cornerRadius: cornerRadius, secondary: true))
    }
}
