import SwiftUI

extension Color {
    /// Triage Signature Cyber Volt (#D4FF3A)
    public static let triageAccent = Color(red: 212 / 255.0, green: 255 / 255.0, blue: 58 / 255.0)
    public static let triageVolt = Color(red: 212 / 255.0, green: 255 / 255.0, blue: 58 / 255.0)
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
