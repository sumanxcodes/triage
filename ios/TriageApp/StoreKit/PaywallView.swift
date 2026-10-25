import SwiftUI
import StoreKit
import ComponentsKit

/// Paywall view presenting Triage Pro subscription tiers and features
public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProductID: String = TriageProductID.annualPro

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            TriageLogoView(size: 64, showsGlow: true)
                                .padding(.top, 8)

                            Text("Triage Pro")
                                .font(RetroTheme.headlineLarge)
                                .foregroundColor(RetroTheme.foreground)

                            AppBadge("ZERO-DAY PROTECTION", color: .accent, isFilled: true)

                            Text("Advanced on-device threat intelligence with real-time AI protection against emerging scams.")
                                .font(RetroTheme.bodySmall)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Feature Highlights
                        AppCard {
                            VStack(alignment: .leading, spacing: 14) {
                                AppSectionHeader("PRO CAPABILITIES")

                                featureRow(
                                    icon: "sparkles",
                                    title: "Zero-Day AI Analysis",
                                    subtitle: "Real-time visual and structural inspection for brand-new deceptive phishing forms."
                                )

                                Divider()

                                featureRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Continuous Threat Updates",
                                    subtitle: "Automatic background synchronization with verified cybersecurity feeds."
                                )

                                Divider()

                                featureRow(
                                    icon: "shield.lefthalf.filled",
                                    title: "Advanced Normalization",
                                    subtitle: "Decodes obfuscated and punycode URLs before evaluating safety."
                                )

                                Divider()

                                featureRow(
                                    icon: "lock.shield.fill",
                                    title: "Zero-Data Retention",
                                    subtitle: "100% on-device filtering. Messages and browsing history never leave your iPhone."
                                )
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 16)

                        // Pricing & Tier Selection
                        VStack(spacing: 10) {
                            if subscriptionManager.products.isEmpty && subscriptionManager.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Connecting to App Store...")
                                        .font(RetroTheme.captionLarge)
                                        .foregroundColor(RetroTheme.secondaryForeground)
                                }
                                .padding()
                            } else if !subscriptionManager.products.isEmpty {
                                ForEach(subscriptionManager.products) { product in
                                    productCard(product: product)
                                }
                            } else {
                                // Fallback preview placeholders
                                fallbackProductCard(
                                    id: TriageProductID.annualPro,
                                    title: "Annual Protection",
                                    price: "$39.99 / year",
                                    detail: "$3.33/mo • Save 33%",
                                    badge: "BEST VALUE"
                                )

                                fallbackProductCard(
                                    id: TriageProductID.monthlyPro,
                                    title: "Monthly Protection",
                                    price: "$4.99 / month",
                                    detail: "Billed monthly • Cancel anytime",
                                    badge: nil
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // Error Banner if present
                        if let error = subscriptionManager.errorMessage {
                            Text(error)
                                .font(RetroTheme.captionMedium)
                                .foregroundColor(RetroTheme.danger)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }

                        // Primary Purchase Button
                        VStack(spacing: 12) {
                            SUButton(
                                title: purchaseButtonTitle,
                                color: .primary,
                                style: .filled,
                                size: .large,
                                isFullWidth: true,
                                isEnabled: !subscriptionManager.isPurchasing
                            ) {
                                handlePurchase()
                            }

                            Button(action: {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                    if subscriptionManager.isProUser {
                                        dismiss()
                                    }
                                }
                            }) {
                                Text("Restore Purchases")
                                    .font(RetroTheme.buttonSmall)
                                    .foregroundColor(RetroTheme.secondaryForeground)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 16)

                        // Legal Footnote (Apple App Store Guideline 3.1.2)
                        VStack(spacing: 6) {
                            Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period in Apple ID Account Settings.")
                                .font(RetroTheme.captionSmall)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 12) {
                                Link("Privacy Policy", destination: URL(string: "https://sumanxcodes.github.io/triage/privacy")!)
                                Text("•")
                                Link("Terms of Service", destination: URL(string: "https://sumanxcodes.github.io/triage/terms")!)
                            }
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Triage Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(RetroTheme.buttonSmall)
                    .foregroundColor(RetroTheme.accent)
                }
            }
        }
    }

    // MARK: - Components

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AppIconWell(
                icon: icon,
                iconColor: RetroTheme.accent,
                backgroundColor: RetroTheme.content1,
                size: 34,
                iconSize: 15
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RetroTheme.headlineSmall)
                    .foregroundColor(RetroTheme.foreground)

                Text(subtitle)
                    .font(RetroTheme.captionMedium)
                    .foregroundColor(RetroTheme.secondaryForeground)
                    .lineSpacing(1.5)
            }
            Spacer()
        }
    }

    private func productCard(product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isAnnual = product.id == TriageProductID.annualPro

        return Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedProductID = product.id
        }) {
            AppCard(cornerRadius: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(isAnnual ? "Annual Protection" : "Monthly Protection")
                                .font(RetroTheme.headlineSmall)
                                .foregroundColor(RetroTheme.foreground)

                            if isAnnual {
                                AppBadge("SAVE 33%", color: .accent, isFilled: true)
                            }
                        }

                        Text(isAnnual ? "Billed annually • Cancel anytime" : "Billed monthly • Cancel anytime")
                            .font(RetroTheme.captionMedium)
                            .foregroundColor(RetroTheme.secondaryForeground)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(RetroTheme.headlineSmall)
                            .foregroundColor(RetroTheme.foreground)

                        Text(isAnnual ? "/ year" : "/ month")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)
                    }

                    ZStack {
                        Circle()
                            .stroke(isSelected ? RetroTheme.accent : RetroTheme.border, lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        if isSelected {
                            Circle()
                                .fill(RetroTheme.accent)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(14)
                .background(isSelected ? RetroTheme.accent.opacity(0.08) : Color.clear)
            }
        }
        .buttonStyle(.plain)
    }

    private func fallbackProductCard(id: String, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedProductID == id

        return Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedProductID = id
        }) {
            AppCard(cornerRadius: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(title)
                                .font(RetroTheme.headlineSmall)
                                .foregroundColor(RetroTheme.foreground)

                            if let badge = badge {
                                AppBadge(badge, color: .accent, isFilled: true)
                            }
                        }

                        Text(detail)
                            .font(RetroTheme.captionMedium)
                            .foregroundColor(RetroTheme.secondaryForeground)
                    }

                    Spacer()

                    Text(price)
                        .font(RetroTheme.headlineSmall)
                        .foregroundColor(RetroTheme.foreground)

                    ZStack {
                        Circle()
                            .stroke(isSelected ? RetroTheme.accent : RetroTheme.border, lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        if isSelected {
                            Circle()
                                .fill(RetroTheme.accent)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(14)
                .background(isSelected ? RetroTheme.accent.opacity(0.08) : Color.clear)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private var purchaseButtonTitle: String {
        if subscriptionManager.isPurchasing {
            return "Processing Purchase..."
        }
        let isAnnual = selectedProductID == TriageProductID.annualPro
        return isAnnual ? "Continue with Annual" : "Continue with Monthly"
    }

    private func handlePurchase() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) {
            Task {
                let success = await subscriptionManager.purchase(product)
                if success {
                    dismiss()
                }
            }
        } else {
            // Simulator or StoreKit sandbox fallback
            Task {
                await subscriptionManager.purchaseMock(id: selectedProductID)
                dismiss()
            }
        }
    }
}
