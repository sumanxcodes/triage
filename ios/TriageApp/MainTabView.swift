import SwiftUI
import UIKit

// MARK: - Native iOS Tab Bar Controller (Apple HIG Standard)

public struct NativeTabBarView: UIViewControllerRepresentable {
    @Binding public var selectedTab: Int
    public var unreadCount: Int

    public init(selectedTab: Binding<Int>, unreadCount: Int) {
        self._selectedTab = selectedTab
        self.unreadCount = unreadCount
    }

    public func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.delegate = context.coordinator

        // Standard Apple HIG Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        tabBarController.tabBar.tintColor = UIColor(RetroTheme.accent)
        tabBarController.tabBar.unselectedItemTintColor = UIColor.secondaryLabel

        // 1. Protection Tab (Unselected: shield outline, Selected: shield.fill)
        let protectionVC = UIHostingController(rootView: ContentView())
        protectionVC.tabBarItem = UITabBarItem(
            title: "Protection",
            image: UIImage(systemName: "shield"),
            selectedImage: UIImage(systemName: "shield.fill")
        )
        protectionVC.tabBarItem.tag = 0

        // 2. History Tab (Unselected: clock outline, Selected: clock.fill)
        let historyVC = UIHostingController(rootView: ThreatHistoryView())
        historyVC.tabBarItem = UITabBarItem(
            title: "History",
            image: UIImage(systemName: "clock"),
            selectedImage: UIImage(systemName: "clock.fill")
        )
        historyVC.tabBarItem.tag = 1
        if unreadCount > 0 {
            historyVC.tabBarItem.badgeValue = "\(unreadCount)"
        }

        // 3. Settings Tab (Unselected: gearshape outline, Selected: gearshape.fill)
        let settingsVC = UIHostingController(rootView: SettingsView())
        settingsVC.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        settingsVC.tabBarItem.tag = 2

        tabBarController.viewControllers = [protectionVC, historyVC, settingsVC]
        tabBarController.selectedIndex = selectedTab

        return tabBarController
    }

    public func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        if uiViewController.selectedIndex != selectedTab {
            uiViewController.selectedIndex = selectedTab
        }

        // Update badge on History tab (index 1)
        if let items = uiViewController.tabBar.items, items.count > 1 {
            items[1].badgeValue = unreadCount > 0 ? "\(unreadCount)" : nil
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITabBarControllerDelegate {
        var parent: NativeTabBarView

        init(_ parent: NativeTabBarView) {
            self.parent = parent
        }

        public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            parent.selectedTab = viewController.tabBarItem.tag
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
                NativeTabBarView(selectedTab: $selectedTab, unreadCount: unreadCount)
                    .ignoresSafeArea(.all, edges: .bottom)
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
