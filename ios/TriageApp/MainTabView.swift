import SwiftUI

// MARK: - App Navigation Tab Definition

public enum AppTab: Int, CaseIterable, Identifiable {
    case protection = 0
    case history = 1
    case settings = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .protection: return "Protection"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    /// Outline SF Symbol strictly displayed when the tab is unselected
    public var outlineSymbol: String {
        switch self {
        case .protection: return "shield"
        case .history: return "clock"
        case .settings: return "gearshape"
        }
    }

    /// Filled SF Symbol strictly displayed when the tab is selected
    public var filledSymbol: String {
        switch self {
        case .protection: return "shield.fill"
        case .history: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }

    public func symbol(isSelected: Bool) -> String {
        isSelected ? filledSymbol : outlineSymbol
    }
}

// MARK: - Navigation Bar Item View

private struct NavBarItemView: View {
    let tab: AppTab
    let isSelected: Bool
    let unreadCount: Int
    var namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 3) {
            iconView
            titleView
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(RetroTheme.accent.opacity(0.14))
                    .matchedGeometryEffect(id: "activeTabBackground", in: namespace)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: tab.symbol(isSelected: isSelected))
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? RetroTheme.accent : RetroTheme.secondaryForeground)
                .frame(height: 22)

            if tab == .history && unreadCount > 0 {
                badgeView
            }
        }
    }

    private var badgeView: some View {
        let badgeText = unreadCount > 99 ? "99+" : "\(unreadCount)"
        return Text(badgeText)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .frame(minWidth: 14, minHeight: 14)
            .background(Color.red)
            .clipShape(Capsule())
            .offset(x: 10, y: -4)
    }

    private var titleView: some View {
        Text(tab.title)
            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            .foregroundColor(isSelected ? RetroTheme.accent : RetroTheme.secondaryForeground)
    }
}

// MARK: - Custom Floating Navigation Bar

public struct CustomFloatingNavBar: View {
    @Binding public var selectedTab: Int
    public var unreadCount: Int
    @Namespace private var tabAnimation

    public init(selectedTab: Binding<Int>, unreadCount: Int) {
        self._selectedTab = selectedTab
        self.unreadCount = unreadCount
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab.rawValue

                Button {
                    if selectedTab != tab.rawValue {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            selectedTab = tab.rawValue
                        }
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                } label: {
                    NavBarItemView(
                        tab: tab,
                        isSelected: isSelected,
                        unreadCount: unreadCount,
                        namespace: tabAnimation
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(uiColor: .systemBackground).opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - Root Main Tab View

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
                ZStack(alignment: .bottom) {
                    ZStack {
                        ContentView()
                            .opacity(selectedTab == 0 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 0)

                        ThreatHistoryView()
                            .opacity(selectedTab == 1 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 1)

                        SettingsView()
                            .opacity(selectedTab == 2 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    CustomFloatingNavBar(selectedTab: $selectedTab, unreadCount: unreadCount)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
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
