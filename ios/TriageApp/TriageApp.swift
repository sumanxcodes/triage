import SwiftUI

extension Color {
    /// Triage Signature Cyber Volt (#D4FF3A)
    public static let triageAccent = Color(red: 212 / 255.0, green: 255 / 255.0, blue: 58 / 255.0)
    public static let triageVolt = Color(red: 212 / 255.0, green: 255 / 255.0, blue: 58 / 255.0)
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
