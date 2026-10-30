import SwiftUI

// MARK: – Color Palette

extension Color {
    static let ftPrimary = Color(hex: "#2BEE6C")
    static let ftBackgroundDark = Color(hex: "#102216")
    static let ftSurfaceDark = Color(hex: "#1C2E22")
    static let ftDeepCharcoal = Color(hex: "#0F172A")
}

// MARK: – Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let uicord = NSColor(self).usingColorSpace(.deviceRGB)
        guard let r = uicord?.redComponent,
              let g = uicord?.greenComponent,
              let b = uicord?.blueComponent else { return nil }

        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}

// MARK: – Glass Panel Modifier

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.ftSurfaceDark.opacity(0.6))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius))
    }
}

// MARK: – Neon Glow

struct NeonGlowModifier: ViewModifier {
    var color: Color = .ftPrimary
    var radius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius)
            .shadow(color: color.opacity(0.1), radius: radius * 2)
    }
}

extension View {
    func neonGlow(color: Color = .ftPrimary, radius: CGFloat = 20) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }
}

// MARK: – Background Gradient

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.ftDeepCharcoal, Color.ftBackgroundDark]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}

// MARK: – Tag Color Helper

extension Tag {
    var color: Color {
        Color(hex: colorHex)
    }
}
