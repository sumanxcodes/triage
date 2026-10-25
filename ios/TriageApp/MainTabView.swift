import SwiftUI
import UIKit

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
                            Label("Protection", systemImage: "shield")
                        }
                        .modifier(TabItemImagesModifier(unselected: "shield", selected: "shield.fill"))
                        .tag(0)

                    ThreatHistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                        .modifier(TabItemImagesModifier(unselected: "clock", selected: "clock.fill"))
                        .badge(unreadCount > 0 ? unreadCount : 0)
                        .tag(1)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .modifier(TabItemImagesModifier(unselected: "gearshape", selected: "gearshape.fill"))
                        .tag(2)
                }
                .tint(RetroTheme.accent)
                .background(NativeTabBarConfigurator())
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

// MARK: - Native Tab Bar Configurator for Outline (Unselected) & Fill (Selected)

private struct NativeTabBarConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            applyTabBarImages(from: vc)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            applyTabBarImages(from: uiViewController)
        }
    }

    private func applyTabBarImages(from vc: UIViewController) {
        var current: UIViewController? = vc
        while let parent = current?.parent {
            if let tbc = parent as? UITabBarController, let items = tbc.tabBar.items, items.count >= 3 {
                items[0].image = UIImage(systemName: "shield")
                items[0].selectedImage = UIImage(systemName: "shield.fill")

                items[1].image = UIImage(systemName: "clock")
                items[1].selectedImage = UIImage(systemName: "clock.fill")

                items[2].image = UIImage(systemName: "gearshape")
                items[2].selectedImage = UIImage(systemName: "gearshape.fill")
                return
            }
            current = parent
        }
    }
}

private struct TabItemImagesModifier: ViewModifier {
    let unselected: String
    let selected: String

    func body(content: Content) -> some View {
        content.background(
            TabItemAccessor(unselected: unselected, selected: selected)
        )
    }
}

private struct TabItemAccessor: UIViewControllerRepresentable {
    let unselected: String
    let selected: String

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            apply(from: vc)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            apply(from: uiViewController)
        }
    }

    private func apply(from vc: UIViewController) {
        var current: UIViewController? = vc
        while let parent = current?.parent {
            if let item = parent.tabBarItem {
                item.image = UIImage(systemName: unselected)
                item.selectedImage = UIImage(systemName: selected)
            }
            if let tbc = parent as? UITabBarController, let items = tbc.tabBar.items, items.count >= 3 {
                items[0].image = UIImage(systemName: "shield")
                items[0].selectedImage = UIImage(systemName: "shield.fill")

                items[1].image = UIImage(systemName: "clock")
                items[1].selectedImage = UIImage(systemName: "clock.fill")

                items[2].image = UIImage(systemName: "gearshape")
                items[2].selectedImage = UIImage(systemName: "gearshape.fill")
            }
            current = parent
        }
    }
}
