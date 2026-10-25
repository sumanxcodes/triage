import SwiftUI
import StoreKit
import ComponentsKit

public struct SettingsView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @AppStorage("triage_has_completed_onboarding_v2") private var hasCompletedOnboarding: Bool = true

    @State private var showingPaywall = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var isRestoring = false
    @State private var restoreStatusMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - 1. Membership & Subscription
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("MEMBERSHIP")

                            AppCard {
                                VStack(spacing: 14) {
                                    HStack(spacing: 14) {
                                        TriageLogoView(size: 44, showsGlow: subscriptionManager.isProUser)

                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 8) {
                                                Text(subscriptionManager.isProUser ? "Triage Pro" : "Triage Free")
                                                    .font(RetroTheme.headlineSmall)
                                                    .foregroundColor(RetroTheme.foreground)

                                                if subscriptionManager.isProUser {
                                                    AppBadge("PRO", color: .accent, isFilled: true)
                                                }
                                            }

                                            Text(subscriptionManager.isProUser ?
                                                 "Zero-day AI protection and continuous threat updates." :
                                                 "Standard on-device scam and phishing protection.")
                                                .font(RetroTheme.captionMedium)
                                                .foregroundColor(RetroTheme.secondaryForeground)
                                        }
                                        Spacer()
                                    }

                                    if !subscriptionManager.isProUser {
                                        SUButton(
                                            title: "Upgrade to Triage Pro",
                                            color: .primary,
                                            style: .filled,
                                            size: .medium,
                                            isFullWidth: true
                                        ) {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            showingPaywall = true
                                        }
                                        .padding(.top, 2)
                                    }

                                    Divider()

                                    HStack {
                                        Button(action: restorePurchases) {
                                            HStack(spacing: 6) {
                                                if isRestoring {
                                                    ProgressView()
                                                        .scaleEffect(0.7)
                                                } else {
                                                    Image(systemName: "arrow.clockwise")
                                                        .font(RetroTheme.captionMedium)
                                                }
                                                Text("Restore Purchases")
                                                    .font(RetroTheme.buttonSmall)
                                            }
                                            .foregroundColor(RetroTheme.foreground)
                                        }
                                        .disabled(isRestoring)

                                        Spacer()

                                        Button(action: openAppleSubscriptions) {
                                            HStack(spacing: 4) {
                                                Text("Manage")
                                                    .font(RetroTheme.captionMedium)
                                                Image(systemName: "arrow.up.forward")
                                                    .font(RetroTheme.captionSmall)
                                            }
                                            .foregroundColor(RetroTheme.secondaryForeground)
                                        }
                                    }

                                    if let msg = restoreStatusMessage {
                                        Text(msg)
                                            .font(RetroTheme.captionMedium)
                                            .foregroundColor(RetroTheme.success)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(16)
                            }
                        }

                        // MARK: - 2. Help & Support
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("HELP & SUPPORT")

                            AppCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: FAQView()) {
                                        menuRow(title: "FAQ & How It Works", icon: "questionmark.circle.fill", iconColor: RetroTheme.accent)
                                    }

                                    Divider()

                                    Button(action: reportThreat) {
                                        menuRow(title: "Report Threat or False Positive", icon: "flag.fill", iconColor: RetroTheme.warning)
                                    }

                                    Divider()

                                    Button(action: contactSupport) {
                                        menuRow(title: "Contact Support", icon: "envelope.fill", iconColor: RetroTheme.secondaryForeground)
                                    }

                                    Divider()

                                    Button(action: {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                            hasCompletedOnboarding = false
                                        }
                                    }) {
                                        menuRow(title: "Replay Onboarding Tour", icon: "arrow.counterclockwise", iconColor: RetroTheme.accent)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                            }
                        }

                        // MARK: - 3. Privacy & Legal
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("PRIVACY & LEGAL")

                            AppCard {
                                VStack(spacing: 0) {
                                    Button(action: { showingPrivacyPolicy = true }) {
                                        menuRow(title: "Privacy Policy", icon: "lock.shield.fill", iconColor: RetroTheme.accent)
                                    }

                                    Divider()

                                    Button(action: { showingTermsOfService = true }) {
                                        menuRow(title: "Terms of Service", icon: "doc.text.fill", iconColor: RetroTheme.secondaryForeground)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                            }
                        }

                        // MARK: - 4. About & Engine Metrics
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("ABOUT")

                            AppCard {
                                VStack(spacing: 12) {
                                    AppDetailRow(label: "Version", value: "1.0.0 (Build 1)")
                                    Divider()
                                    AppDetailRow(label: "Architecture", value: "On-Device Protection")
                                    Divider()
                                    AppDetailRow(label: "Telemetry", value: "Zero Data Collected")
                                }
                                .padding(16)
                            }
                        }

                        Text("Triage is designed and built for on-device privacy.")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground.opacity(0.7))
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicySheet()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceSheet()
            }
        }
    }

    private func menuRow(title: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(RetroTheme.bodyMedium)
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(title)
                .font(RetroTheme.bodySmall)
                .foregroundColor(RetroTheme.foreground)

            Spacer()

            Image(systemName: "chevron.right")
                .font(RetroTheme.captionSmall)
                .foregroundColor(RetroTheme.secondaryForeground)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func restorePurchases() {
        isRestoring = true
        restoreStatusMessage = nil
        Task {
            await subscriptionManager.restorePurchases()
            await MainActor.run {
                isRestoring = false
                restoreStatusMessage = "Purchases restored successfully."
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func openAppleSubscriptions() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    private func reportThreat() {
        if let url = URL(string: "mailto:support@triage-security.app?subject=Threat%20Report%20/%20False%20Positive") {
            UIApplication.shared.open(url)
        }
    }

    private func contactSupport() {
        if let url = URL(string: "mailto:support@triage-security.app?subject=Triage%20Support%20Inquiry") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - FAQ View

struct FAQView: View {
    private struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private let faqs: [FAQItem] = [
        FAQItem(
            question: "Can Triage read my private texts or bank OTPs?",
            answer: "No. Apple's IdentityLookup sandbox strictly isolates messages. Messages from your saved Contacts are completely bypassed and never routed to Triage. For unknown senders, Triage only extracts link URLs and checks cryptographic SHA-256 hashes locally on-device. Message text, sender phone numbers, and bank 2FA codes are never stored, logged, or sent to any server."
        ),
        FAQItem(
            question: "Does the Safari extension track my browsing?",
            answer: "Never. The Triage Safari Extension runs strictly within WebKit's sandbox. It evaluates domain candidate hashes against the local database in under 1 millisecond. Your browsing history, visited tabs, search queries, and form inputs never leave your device."
        ),
        FAQItem(
            question: "Why do I need to enable Triage manually?",
            answer: "Apple's security architecture gives you total control over extensions. iOS prohibits apps from silently turning on filters in the background. You must grant permission manually in Settings > Messages and Settings > Safari."
        ),
        FAQItem(
            question: "Does Triage protect me offline in Airplane Mode?",
            answer: "Yes, 100%. The entire threat intelligence database is stored on your device in an optimized on-device database. Incoming SMS and Safari links are protected even with no Wi-Fi or cellular connection."
        ),
        FAQItem(
            question: "What is Zero-Day AI protection?",
            answer: "For Triage Pro subscribers, brand-new evasive threats not yet listed in global threat feeds undergo real-time visual and structural inspection. This stops brand mimicry, deceptive login forms, and credential harvesters on day zero."
        )
    ]

    var body: some View {
        ZStack {
            RetroTheme.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(faqs) { item in
                        AppCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.question)
                                    .font(RetroTheme.headlineSmall)
                                    .foregroundColor(RetroTheme.foreground)

                                Text(item.answer)
                                    .font(RetroTheme.bodySmall)
                                    .foregroundColor(RetroTheme.secondaryForeground)
                                    .lineSpacing(2)
                            }
                            .padding(14)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy Sheet

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            AppIconWell(
                                icon: "lock.shield.fill",
                                iconColor: RetroTheme.accent,
                                backgroundColor: RetroTheme.content1,
                                size: 44,
                                iconSize: 20
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Privacy Policy")
                                    .font(RetroTheme.headlineMedium)
                                    .foregroundColor(RetroTheme.foreground)
                                Text("Zero telemetry guarantee • Audited Apple manifest")
                                    .font(RetroTheme.captionSmall)
                                    .foregroundColor(RetroTheme.secondaryForeground)
                            }
                        }
                        .padding(.top, 8)

                        policyBlock(
                            title: "1. Zero-Telemetry Architecture",
                            body: "Triage is built on a strict privacy model: zero accounts required (no email, password, or sign-in), zero analytics SDKs (no tracking, profiling, or ads), and zero telemetry transmitted during SMS or web evaluation."
                        )

                        policyBlock(
                            title: "2. SMS Message Filtering",
                            body: "Under Apple's IdentityLookup API, messages from people saved in your Contacts are never routed to Triage. When an unknown message is received, Triage extracts link URLs and calculates cryptographic SHA-256 hashes locally. The text of your messages, sender phone numbers, and two-factor verification codes are never stored, transmitted, or logged."
                        )

                        policyBlock(
                            title: "3. Safari Web Shield",
                            body: "The Triage Safari Extension evaluates website URLs using on-device lookups in under 1 millisecond. Your browsing history, visited URLs, bookmarks, and search queries are never uploaded or retained."
                        )

                        policyBlock(
                            title: "4. Network Updates",
                            body: "The only network communication performed by Triage is anonymous, scheduled delta syncs to download the latest cryptographic threat hashes from our verified security feeds. These requests contain no device identifiers or personal information."
                        )

                        policyBlock(
                            title: "5. Audited Apple Privacy Manifest",
                            body: "Triage includes an audited Apple Privacy Manifest (PrivacyInfo.xcprivacy) declaring zero tracking and zero collected data types across all targets."
                        )
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(RetroTheme.buttonSmall)
                    .foregroundColor(RetroTheme.accent)
                }
            }
        }
    }

    private func policyBlock(title: String, body: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(RetroTheme.bodyMedium)
                    .foregroundColor(RetroTheme.foreground)
                Text(body)
                    .font(RetroTheme.bodySmall)
                    .foregroundColor(RetroTheme.secondaryForeground)
                    .lineSpacing(2)
            }
            .padding(12)
        }
    }
}

// MARK: - Terms of Service Sheet

struct TermsOfServiceSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Terms of Service")
                            .font(RetroTheme.headlineMedium)
                            .foregroundColor(RetroTheme.foreground)
                            .padding(.top, 8)

                        Text("Standard Apple EULA & subscription terms")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)

                        termsBlock(
                            title: "1. Acceptance of Terms",
                            body: "By downloading, installing, or using Triage, you agree to be bound by these Terms of Service and Apple's Standard Licensed Application End User License Agreement (EULA)."
                        )

                        termsBlock(
                            title: "2. Security & Threat Intelligence",
                            body: "Triage provides on-device smishing and phishing interception based on verified threat intelligence feeds and heuristic analysis. While Triage strives for highest accuracy, no cybersecurity tool can guarantee 100% prevention of all emerging attacks. Users are advised to exercise vigilance."
                        )

                        termsBlock(
                            title: "3. Subscriptions & Billing",
                            body: "Triage Pro is offered as an auto-renewing subscription through Apple In-App Purchase. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing cycle in your Apple ID Account Settings."
                        )

                        termsBlock(
                            title: "4. Permitted Use",
                            body: "You may use Triage strictly for personal or internal organizational device protection. Reverse engineering, decompiling, or attempting to compromise the security mechanisms of Triage is strictly prohibited."
                        )

                        termsBlock(
                            title: "5. Limitation of Liability",
                            body: "To the maximum extent permitted by applicable law, Triage and its developers shall not be liable for any indirect, incidental, or consequential damages arising from the use of or inability to use the service."
                        )
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(RetroTheme.buttonSmall)
                    .foregroundColor(RetroTheme.accent)
                }
            }
        }
    }

    private func termsBlock(title: String, body: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(RetroTheme.bodyMedium)
                    .foregroundColor(RetroTheme.foreground)
                Text(body)
                    .font(RetroTheme.bodySmall)
                    .foregroundColor(RetroTheme.secondaryForeground)
                    .lineSpacing(2)
            }
            .padding(12)
        }
    }
}
