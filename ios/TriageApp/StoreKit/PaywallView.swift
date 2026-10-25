import SwiftUI
import StoreKit
import ComponentsKit

/// Retro-themed Paywall view presenting Triage Pro subscription tiers and features
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

                ScrollView {
                    VStack(spacing: 22) {
                        // Header
                        VStack(spacing: 10) {
                            TriageLogoView(size: 72, showsGlow: true)
                                .padding(.top, 12)

                            Text("TRIAGE PRO")
                                .font(.system(size: 24, weight: .heavy, design: .monospaced))
                                .foregroundColor(.primary)

                            RetroBadge("ZERO-DAY CYBER DEFENSE", color: RetroTheme.textAccent, isFilled: true)

                            Text("Advanced threat intelligence powered by on-device SQLite lookups and Gemini zero-day heuristics.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Feature Card
                        RetroCard(cornerRadius: 10) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("// PRO CAPABILITIES")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.secondary)

                                featureRow(
                                    tag: "GEMINI AI",
                                    title: "ZERO-DAY VISUAL ANALYSIS",
                                    subtitle: "Real-time Google Gemini visual & DOM analysis for brand-new deceptive phishing forms."
                                )

                                Divider()

                                featureRow(
                                    tag: "DELTA SYNC",
                                    title: "CONTINUOUS THREAT FEED",
                                    subtitle: "Hourly background SQLite hash sync with global verified cybersecurity feeds."
                                )

                                Divider()

                                featureRow(
                                    tag: "DE-OBFUSCATE",
                                    title: "ADVANCED NORMALIZATION",
                                    subtitle: "Multi-layer decoding against evasive Punycode, homographs, and octal IP masks."
                                )

                                Divider()

                                featureRow(
                                    tag: "AIR-GAPPED",
                                    title: "ZERO-DATA RETENTION",
                                    subtitle: "100% stateless filtering. Messages and browsing history never leave your iPhone."
                                )
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 16)

                        // Pricing & Tier Selection
                        VStack(spacing: 12) {
                            if subscriptionManager.products.isEmpty && subscriptionManager.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("CONNECTING TO APP STORE...")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.secondary)
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
                                    title: "ANNUAL PROTECTION",
                                    price: "$39.99 / YEAR",
                                    detail: "$3.33/MO // SAVE 33%",
                                    badge: "BEST VALUE"
                                )

                                fallbackProductCard(
                                    id: TriageProductID.monthlyPro,
                                    title: "MONTHLY PROTECTION",
                                    price: "$4.99 / MONTH",
                                    detail: "BILLED MONTHLY // CANCEL ANYTIME",
                                    badge: nil
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // Error Banner if present
                        if let error = subscriptionManager.errorMessage {
                            Text(error)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.red)
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
                                Text("[ RESTORE PURCHASES ]")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 16)

                        // Legal Footnote (Apple App Store Guideline 3.1.2)
                        VStack(spacing: 6) {
                            Text("Subscriptions automatically renew unless auto-renew is turned off at least 24-hours before the end of the current period in Apple ID Settings.")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(.tertiaryLabel))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 12) {
                                Link("PRIVACY POLICY", destination: URL(string: "https://sumanxcodes.github.io/triage/privacy")!)
                                Text("•")
                                Link("TERMS OF SERVICE", destination: URL(string: "https://sumanxcodes.github.io/triage/terms")!)
                            }
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("TRIAGE PRO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        RetroBadge("CLOSE", color: .secondary, isFilled: false)
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func featureRow(tag: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RetroBadge(tag, color: RetroTheme.textAccent, isFilled: true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
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
            RetroCard(cornerRadius: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(product.displayName.isEmpty ? (isAnnual ? "ANNUAL PROTECTION" : "MONTHLY PROTECTION") : product.displayName.uppercased())
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundColor(.primary)

                            if isAnnual {
                                RetroBadge("SAVE 33%", color: RetroTheme.textAccent, isFilled: true)
                            }
                        }

                        Text(isAnnual ? "BILLED ANNUALLY // CANCEL ANYTIME" : "BILLED MONTHLY // CANCEL ANYTIME")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundColor(.primary)

                        Text(isAnnual ? "/ YEAR" : "/ MONTH")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    ZStack {
                        Rectangle()
                            .stroke(RetroTheme.border, lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        if isSelected {
                            Rectangle()
                                .fill(RetroTheme.volt)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(14)
                .background(isSelected ? RetroTheme.volt.opacity(0.08) : Color.clear)
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
            RetroCard(cornerRadius: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundColor(.primary)

                            if let badge = badge {
                                RetroBadge(badge, color: RetroTheme.textAccent, isFilled: true)
                            }
                        }

                        Text(detail)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(price)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.primary)

                    ZStack {
                        Rectangle()
                            .stroke(RetroTheme.border, lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        if isSelected {
                            Rectangle()
                                .fill(RetroTheme.volt)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(14)
                .background(isSelected ? RetroTheme.volt.opacity(0.08) : Color.clear)
            }
        }
        .buttonStyle(.plain)
    }

    private var purchaseButtonTitle: String {
        if let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) {
            return "SUBSCRIBE FOR \(product.displayPrice)"
        }
        return selectedProductID == TriageProductID.annualPro ? "SUBSCRIBE FOR $39.99 / YR" : "SUBSCRIBE FOR $4.99 / MO"
    }

    private func handlePurchase() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) {
            Task {
                do {
                    let transaction = try await subscriptionManager.purchase(product)
                    if transaction != nil {
                        dismiss()
                    }
                } catch {
                    print("[Paywall] Purchase failed: \(error)")
                }
            }
        } else {
            subscriptionManager.errorMessage = "Connecting to App Store Sandbox..."
        }
    }
}
