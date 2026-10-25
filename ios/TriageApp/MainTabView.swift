import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @AppStorage("triage_last_viewed_history_date") private var lastViewedTimestamp: Double = 0
    @AppStorage("triage_has_completed_onboarding_v2") private var hasCompletedOnboarding: Bool = false
    @State private var unreadCount: Int = 0

    public init() {}

    public var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.96))
                ))
            } else {
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
                .tint(RetroTheme.accent)
                .transition(.opacity)
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
