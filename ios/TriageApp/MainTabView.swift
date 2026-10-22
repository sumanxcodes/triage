import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @AppStorage("triage_last_viewed_history_date") private var lastViewedTimestamp: Double = 0
    @State private var unreadCount: Int = 0

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
                .badge(unreadCount > 0 ? unreadCount : 0)
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .onAppear {
            refreshBadge()
        }
        .onChange(of: selectedTab) {
            if selectedTab == 1 {
                // User viewed History: acknowledge and clear unread badge
                lastViewedTimestamp = Date().timeIntervalSince1970
                unreadCount = 0
            } else {
                refreshBadge()
            }
        }
    }

    private func refreshBadge() {
        if selectedTab == 1 {
            unreadCount = 0
            return
        }
        if lastViewedTimestamp > 0 {
            let lastDate = Date(timeIntervalSince1970: lastViewedTimestamp)
            unreadCount = ThreatDatabase.shared.unreadEventsCount(since: lastDate)
        } else {
            unreadCount = ThreatDatabase.shared.eventsCount()
        }
    }
}
