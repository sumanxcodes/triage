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
                        // MARK: - 1. Subscription & Plan
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MEMBERSHIP & ACCESS")
                                .font(RetroTheme.captionSmall)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .padding(.horizontal, 4)

                            RetroCard {
                                VStack(spacing: 12) {
                                    HStack(spacing: 14) {
                                        TriageLogoView(size: 44, showsGlow: subscriptionManager.isProUser)

                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(subscriptionManager.isProUser ? "TRIAGE PRO" : "TRIAGE FREE")
                                                    .font(RetroTheme.headlineSmall)
                                                    .foregroundColor(RetroTheme.foreground)

                                                RetroBadge(
                                                    subscriptionManager.isProUser ? "PRO ACTIVE" : "STANDARD",
                                                    color: subscriptionManager.isProUser ? .accent : .primary,
                                                    isFilled: true
                                                )
                                            }

                                            Text(subscriptionManager.isProUser ?
                                                 "Zero-Day AI inspection & continuous threat sync enabled." :
                                                 "Standard on-device SQLite SMS & Safari defense.")
                                                .font(RetroTheme.captionMedium)
                                                .foregroundColor(RetroTheme.secondaryForeground)
                                        }
                                        Spacer()
                                    }

                                    if !subscriptionManager.isProUser {
                                        SUButton(
                                            title: "UPGRADE TO TRIAGE PRO",
                                            color: .primary,
                                            style: .filled,
                                            size: .medium,
                                            isFullWidth: true
                                        ) {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            showingPaywall = true
                                        }
                                        .padding(.top, 4)
                                    }

                                    SUDivider()

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
                                                Text("RESTORE PURCHASES")
                                                    .font(RetroTheme.buttonSmall)
                                            }
                                            .foregroundColor(RetroTheme.foreground)
                                        }
                                        .disabled(isRestoring)

                                        Spacer()

                                        Button(action: openAppleSubscriptions) {
                                            HStack(spacing: 4) {
                                                Text("MANAGE")
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
                            Text("KNOWLEDGE & SUPPORT")
                                .font(RetroTheme.captionSmall)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .padding(.horizontal, 4)

                            RetroCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: FAQView()) {
                                        menuRow(title: "FAQ & ARCHITECTURE", icon: "questionmark.circle.fill", iconColor: RetroTheme.accent)
                                    }

                                    SUDivider()

                                    Button(action: reportThreat) {
                                        menuRow(title: "REPORT THREAT / FALSE POSITIVE", icon: "flag.fill", iconColor: RetroTheme.warning)
                                    }

                                    SUDivider()

                                    Button(action: contactSupport) {
                                        menuRow(title: "CONTACT SECURITY TEAM", icon: "envelope.fill", iconColor: RetroTheme.secondaryForeground)
                                    }

                                    SUDivider()

                                    Button(action: {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                            hasCompletedOnboarding = false
                                        }
                                    }) {
                                        menuRow(title: "REPLAY ONBOARDING TOUR", icon: "arrow.counterclockwise", iconColor: RetroTheme.success)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }

                        // MARK: - 3. Privacy & Legal
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COMPLIANCE & PRIVACY")
                                .font(RetroTheme.captionSmall)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .padding(.horizontal, 4)

                            RetroCard {
                                VStack(spacing: 0) {
                                    Button(action: { showingPrivacyPolicy = true }) {
                                        menuRow(title: "PRIVACY POLICY & ZERO-LOGGING", icon: "lock.shield.fill", iconColor: RetroTheme.success)
                                    }

                                    SUDivider()

                                    Button(action: { showingTermsOfService = true }) {
                                        menuRow(title: "TERMS OF SERVICE (EULA)", icon: "doc.text.fill", iconColor: RetroTheme.secondaryForeground)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }

                        // MARK: - 4. About & Engine Metrics
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ENGINE SPECIFICATION")
                                .font(RetroTheme.captionSmall)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .padding(.horizontal, 4)

                            RetroCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("CORE ENGINE")
                                            .font(RetroTheme.captionLarge)
                                            .foregroundColor(RetroTheme.secondaryForeground)
                                        Spacer()
                                        RetroBadge("SQLITE 3.45 WAL", color: .accent, isFilled: true)
                                    }

                                    SUDivider()

                                    HStack {
                                        Text("BUILD SPEC")
                                            .font(RetroTheme.captionLarge)
                                            .foregroundColor(RetroTheme.secondaryForeground)
                                        Spacer()
                                        Text("v1.0.0 (Build 1)")
                                            .font(RetroTheme.bodySmall)
                                            .foregroundColor(RetroTheme.foreground)
                                    }

                                    SUDivider()

                                    HStack {
                                        Text("SANDBOX")
                                            .font(RetroTheme.captionLarge)
                                            .foregroundColor(RetroTheme.secondaryForeground)
                                        Spacer()
                                        RetroBadge("IDENTITYLOOKUP / WEBKIT", color: .primary, isFilled: false)
                                    }
                                }
                                .padding(16)
                            }
                        }

                        Text("TRIAGE SECURITY // ZERO TELEMETRY // APPLE HIG COMPLIANT")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground.opacity(0.6))
                            .padding(.top, 4)
                            .padding(.bottom, 96)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("SETTINGS")
            .navigationBarTitleDisplayMode(.inline)
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
    }

    // MARK: - Actions

    private func restorePurchases() {
        isRestoring = true
        restoreStatusMessage = nil
        Task {
            await subscriptionManager.restorePurchases()
            await MainActor.run {
                isRestoring = false
                restoreStatusMessage = "PURCHASES RESTORED"
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

// MARK: - Retro FAQ View

struct FAQView: View {
    private struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private let faqs: [FAQItem] = [
        FAQItem(
            question: "CAN TRIAGE READ MY PRIVATE TEXTS OR BANK OTPS?",
            answer: "No. Apple's IdentityLookup sandbox strictly isolates messages. Messages from your saved Contacts are completely bypassed and never routed to Triage. For unknown senders, Triage only extracts link URLs and checks cryptographic SHA-256 hashes locally on-device. Message text, sender phone numbers, and bank 2FA codes are never stored, logged, or sent to any server."
        ),
        FAQItem(
            question: "DOES THE SAFARI EXTENSION TRACK MY BROWSING?",
            answer: "Never. The Triage Safari Extension runs strictly within WebKit's sandbox. It evaluates domain candidate hashes against the local SQLite database in under 1 millisecond. Your browsing history, visited tabs, search queries, and form inputs never leave your device."
        ),
        FAQItem(
            question: "WHY DO I NEED TO ENABLE TRIAGE MANUALLY?",
            answer: "Apple's security architecture gives you total control over extensions. iOS prohibits apps from silently turning on filters in the background. You must grant permission manually in Settings > Messages and Settings > Safari."
        ),
        FAQItem(
            question: "DOES TRIAGE PROTECT ME OFFLINE IN AIRPLANE MODE?",
            answer: "Yes, 100%. The entire threat intelligence database is stored on your device in an optimized SQLite database with WAL indexing. Incoming SMS and Safari links are protected even with no Wi-Fi or cellular connection."
        ),
        FAQItem(
            question: "WHAT IS GEMINI ZERO-DAY AI PROTECTION?",
            answer: "For Triage Pro subscribers, brand-new evasive threats not yet listed in global threat feeds undergo real-time Google Gemini visual and structural inspection. This stops brand mimicry, deceptive login forms, and credential harvesters on day zero."
        )
    ]

    var body: some View {
        ZStack {
            RetroTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(faqs) { item in
                        RetroCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.question)
                                    .font(RetroTheme.bodyMedium)
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

// MARK: - Retro Privacy Policy Sheet

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(RetroTheme.content1)
                                    .frame(width: 44, height: 44)

                                Image(systemName: "lock.shield.fill")
                                    .font(RetroTheme.headlineSmall)
                                    .foregroundColor(RetroTheme.success)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("PRIVACY POLICY")
                                    .font(RetroTheme.headlineMedium)
                                    .foregroundColor(RetroTheme.foreground)
                                Text("Zero-Telemetry Guarantee • Audited Apple Manifest")
                                    .font(RetroTheme.captionSmall)
                                    .foregroundColor(RetroTheme.secondaryForeground)
                            }
                        }
                        .padding(.top, 8)

                        policyBlock(
                            title: "1. ZERO-TELEMETRY ARCHITECTURE",
                            body: "Triage is built on a strict privacy model: zero accounts required (no email, password, or sign-in), zero analytics SDKs (no tracking, profiling, or ads), and zero telemetry transmitted during SMS or web evaluation."
                        )

                        policyBlock(
                            title: "2. SMS MESSAGE FILTERING (IDENTITYLOOKUP)",
                            body: "Under Apple's IdentityLookup API, messages from people saved in your Contacts are NEVER routed to Triage. When an unknown message is received, Triage extracts link URLs and calculates cryptographic SHA-256 hashes locally. The text of your messages, sender phone numbers, and any two-factor verification codes are NEVER stored, transmitted, or logged."
                        )

                        policyBlock(
                            title: "3. SAFARI WEB SHIELD",
                            body: "The Triage Safari Extension evaluates website URLs using on-device SQLite lookups in under 1 millisecond. Your browsing history, visited URLs, bookmarks, and search queries are never uploaded or retained."
                        )

                        policyBlock(
                            title: "4. NETWORK COMMUNICATIONS",
                            body: "The only network communication performed by Triage is anonymous, scheduled delta syncs to download the latest cryptographic threat hashes from our verified security feeds. These requests contain no device identifiers or personal information."
                        )

                        policyBlock(
                            title: "5. AUDITED APPLE PRIVACY MANIFEST",
                            body: "Triage includes an audited Apple Privacy Manifest (PrivacyInfo.xcprivacy) declaring zero tracking and zero collected data types across all targets."
                        )
                    }
                    .padding(16)
                }
            }
            .navigationTitle("PRIVACY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        RetroBadge("DONE", color: .primary, isFilled: false)
                    }
                }
            }
        }
    }

    private func policyBlock(title: String, body: String) -> some View {
        RetroCard {
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

// MARK: - Retro Terms of Service Sheet

struct TermsOfServiceSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TERMS OF SERVICE")
                            .font(RetroTheme.headlineMedium)
                            .foregroundColor(RetroTheme.foreground)
                            .padding(.top, 8)

                        Text("Standard Apple EULA & Subscription Terms")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)

                        termsBlock(
                            title: "1. ACCEPTANCE OF TERMS",
                            body: "By downloading, installing, or using Triage, you agree to be bound by these Terms of Service and Apple's Standard Licensed Application End User License Agreement (EULA)."
                        )

                        termsBlock(
                            title: "2. SECURITY & THREAT INTELLIGENCE",
                            body: "Triage provides on-device smishing and phishing interception based on verified threat intelligence feeds and heuristic analysis. While Triage strives for highest accuracy, no cybersecurity tool can guarantee 100% prevention of all emerging attacks. Users are advised to exercise vigilance."
                        )

                        termsBlock(
                            title: "3. SUBSCRIPTIONS & BILLING",
                            body: "Triage Pro is offered as an auto-renewing subscription through Apple In-App Purchase. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing cycle in your Apple ID Account Settings."
                        )

                        termsBlock(
                            title: "4. PERMITTED USE",
                            body: "You may use Triage strictly for personal or internal organizational device protection. Reverse engineering, decompiling, or attempting to compromise the security mechanisms of Triage is strictly prohibited."
                        )

                        termsBlock(
                            title: "5. LIMITATION OF LIABILITY",
                            body: "To the maximum extent permitted by applicable law, Triage and its developers shall not be liable for any indirect, incidental, or consequential damages arising from the use of or inability to use the service."
                        )
                    }
                    .padding(16)
                }
            }
            .navigationTitle("TERMS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        RetroBadge("DONE", color: .primary, isFilled: false)
                    }
                }
            }
        }
    }

    private func termsBlock(title: String, body: String) -> some View {
        RetroCard {
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
