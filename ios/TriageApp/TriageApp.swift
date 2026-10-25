import SwiftUI
import UIKit

// MARK: - Dynamic Adaptive Color System (Dark & Light Mode Support)

extension UIColor {
    /// Adaptive dynamic color for Triage Volt (#D4FF3A):
    /// - Dark Mode: Electric Cyber Volt (#D4FF3A) with high luminance against dark obsidian backgrounds
    /// - Light Mode: High-contrast Cyber Lime (#446300) with 5.2:1 WCAG AAA contrast against white & light gray
    public static let dynamicTriageVolt = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(red: 212 / 255.0, green: 255 / 255.0, blue: 58 / 255.0, alpha: 1.0)
        } else {
            return UIColor(red: 68 / 255.0, green: 99 / 255.0, blue: 0 / 255.0, alpha: 1.0)
        }
    }

    /// Background subtle tint:
    /// - Dark Mode: 16% opacity of #D4FF3A
    /// - Light Mode: 12% opacity of #446300
    public static let dynamicTriageVoltSubtle = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(red: 212 / 255.0, green: 255 / 255.0, blue: 58 / 255.0, alpha: 0.16)
        } else {
            return UIColor(red: 68 / 255.0, green: 99 / 255.0, blue: 0 / 255.0, alpha: 0.12)
        }
    }

    /// Adaptive card border (frosted rim in dark mode, crisp hairline separation in light mode)
    public static let dynamicCardBorder = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor.white.withAlphaComponent(0.08)
        } else {
            return UIColor.black.withAlphaComponent(0.07)
        }
    }
}

extension Color {
    /// Raw Unaltered Brand Cyber Volt (#D4FF3A) - strictly used for solid button/badge fills where text is .black
    public static let triageVoltRaw = Color(red: 212 / 255.0, green: 255 / 255.0, blue: 58 / 255.0)

    /// Adaptive Triage Volt: automatically optimizes contrast for Dark Mode (#D4FF3A) and Light Mode (#446300)
    public static let triageVolt = Color(uiColor: .dynamicTriageVolt)
    public static let triageAccent = Color(uiColor: .dynamicTriageVolt)

    /// Adaptive subtle volt tint for badge/container backgrounds
    public static let triageVoltSubtle = Color(uiColor: .dynamicTriageVoltSubtle)

    /// Adaptive card border stroke (subtle white in dark mode, subtle dark in light mode)
    public static let triageCardBorder = Color(uiColor: .dynamicCardBorder)
}

// MARK: - Official Triage Brand Logo Emblem

public struct TriageLogoView: View {
    public var size: CGFloat
    public var showsGlow: Bool

    public init(size: CGFloat = 60, showsGlow: Bool = false) {
        self.size = size
        self.showsGlow = showsGlow
    }

    public var body: some View {
        Image("TriageLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: showsGlow ? Color.triageVolt.opacity(0.35) : Color.clear, radius: 10, x: 0, y: 0)
    }
}

@main
struct TriageApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(.triageAccent)
        }
    }
}
