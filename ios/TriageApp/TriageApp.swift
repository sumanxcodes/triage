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
        Image("TriageLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: showsGlow ? RetroTheme.accent.opacity(0.35) : Color.clear, radius: 10, x: 0, y: 0)
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
