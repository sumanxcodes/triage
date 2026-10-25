import SwiftUI
import UIKit
import ComponentsKit

// MARK: - Official Triage Brand Logo Emblem

public struct TriageLogoView: View {
    public var size: CGFloat
    public var showsGlow: Bool

    public init(size: CGFloat = 60, showsGlow: Bool = false) {
        self.size = size
        self.showsGlow = showsGlow
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            RetroTheme.accent,
                            RetroTheme.accent.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: "shield.checkered")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundColor(RetroTheme.accentContrast)
        }
    }
}

@main
struct TriageApp: App {
    init() {
        RetroTheme.configureComponentsKit()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(RetroTheme.accent)
        }
    }
}
