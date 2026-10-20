import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var eventCount: Int = ThreatDatabase.shared.eventsCount()

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Protection", systemImage: "shield.fill")
                }
                .tag(0)

            ThreatHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .badge(eventCount > 0 ? eventCount : 0)
                .tag(1)
        }
        .onAppear {
            refreshBadge()
        }
        .onChange(of: selectedTab) {
            refreshBadge()
        }
    }

    private func refreshBadge() {
        eventCount = ThreatDatabase.shared.eventsCount()
    }
}
