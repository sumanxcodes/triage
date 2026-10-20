import SwiftUI
import StoreKit

/// Paywall view presenting Triage Pro subscription tiers and features
public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProductID: String = TriageProductID.annualPro

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header Badge
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.indigo, .blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 90, height: 90)

                            Image(systemName: "shield.checkered")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 16)

                        Text("Triage Pro")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.heavy)

                        Text("Uncompromising privacy protection powered by on-device intelligence and zero-day AI.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Feature List
                    VStack(alignment: .leading, spacing: 18) {
                        featureRow(
                            icon: "sparkles",
                            color: .purple,
                            title: "Zero-Day AI Analysis",
                            subtitle: "Real-time Google Gemini visual & DOM analysis for new phishing attacks."
                        )

                        featureRow(
                            icon: "arrow.triangle.2.circlepath",
                            color: .blue,
                            title: "Continuous Threat Sync",
                            subtitle: "Hourly background database delta sync with verified threat hashes."
                        )

                        featureRow(
                            icon: "bolt.shield.fill",
                            color: .green,
                            title: "Priority SMS Normalization",
                            subtitle: "Deep multi-layer canonicalization against evasive Punycode & IP obfuscations."
                        )

                        featureRow(
                            icon: "lock.shield.fill",
                            color: .indigo,
                            title: "Zero Data Logging",
                            subtitle: "100% stateless filtering. Your messages and browsing never leave your device."
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Pricing & Tier Selection
                    VStack(spacing: 12) {
                        if subscriptionManager.products.isEmpty && subscriptionManager.isLoading {
                            ProgressView("Loading subscription options...")
                                .padding()
                        } else if !subscriptionManager.products.isEmpty {
                            ForEach(subscriptionManager.products) { product in
                                productCard(product: product)
                            }
                        } else {
                            // Fallback preview placeholders if products unavailable in offline mode
                            fallbackProductCard(
                                id: TriageProductID.annualPro,
                                title: "Annual Protection",
                                price: "$39.99 / year",
                                detail: "$3.33/month — Save 33%",
                                badge: "BEST VALUE"
                            )

                            fallbackProductCard(
                                id: TriageProductID.monthlyPro,
                                title: "Monthly Protection",
                                price: "$4.99 / month",
                                detail: "Billed monthly, cancel anytime",
                                badge: nil
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Error Banner if present
                    if let error = subscriptionManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Primary Purchase Button
                    VStack(spacing: 12) {
                        Button(action: handlePurchase) {
                            HStack {
                                if subscriptionManager.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(purchaseButtonTitle)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(subscriptionManager.isPurchasing)

                        Button(action: {
                            Task {
                                await subscriptionManager.restorePurchases()
                                if subscriptionManager.isProUser {
                                    dismiss()
                                }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)

                    // Legal Footnote (Mandatory App Store Guideline 3.1.2)
                    VStack(spacing: 6) {
                        Text("Subscriptions automatically renew unless auto-renew is turned off at least 24-hours before the end of the current period in your Apple ID Account Settings.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(.tertiaryLabel))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://sumanxcodes.github.io/triage/privacy")!)
                            Text("•")
                                .foregroundColor(Color(.tertiaryLabel))
                            Link("Terms of Service", destination: URL(string: "https://sumanxcodes.github.io/triage/terms")!)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private func productCard(product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isAnnual = product.id == TriageProductID.annualPro

        return Button(action: { selectedProductID = product.id }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName.isEmpty ? (isAnnual ? "Annual Protection" : "Monthly Protection") : product.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isAnnual {
                            Text("SAVE 33%")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    Text(isAnnual ? "Billed annually • Cancel anytime" : "Billed monthly • Cancel anytime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(isAnnual ? "/ year" : "/ month")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : Color(.tertiaryLabel))
                    .font(.title3)
                    .padding(.leading, 8)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func fallbackProductCard(id: String, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedProductID == id

        return Button(action: { selectedProductID = id }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : Color(.tertiaryLabel))
                    .font(.title3)
                    .padding(.leading, 8)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var purchaseButtonTitle: String {
        if selectedProductID == TriageProductID.annualPro {
            return "Start 3-Day Free Trial & Subscribe"
        } else {
            return "Subscribe Now"
        }
    }

    private func handlePurchase() {
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
            // Simulator demo action
            subscriptionManager.errorMessage = "Connecting to App Store Sandbox..."
        }
    }
}
