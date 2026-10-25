import SwiftUI
import StoreKit

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
            List {
                // MARK: - 1. Subscription & Plan
                Section {
                    HStack(spacing: 14) {
                        TriageLogoView(size: 44, showsGlow: subscriptionManager.isProUser)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(subscriptionManager.isProUser ? "Triage Pro" : "Triage Free")
                                    .font(.headline)

                                Text(subscriptionManager.isProUser ? "ACTIVE" : "STANDARD")
                                    .font(.system(size: 9, weight: .heavy))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(subscriptionManager.isProUser ? Color.triageVolt.opacity(0.2) : Color.secondary.opacity(0.2))
                                    .foregroundColor(subscriptionManager.isProUser ? .triageVolt : .secondary)
                                    .cornerRadius(4)
                            }

                            Text(subscriptionManager.isProUser ?
                                 "Zero-Day Gemini AI and hourly sync enabled." :
                                 "On-device SQLite SMS & Safari protection.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if !subscriptionManager.isProUser {
                        Button(action: { showingPaywall = true }) {
                            HStack {
                                Label("Upgrade to Triage Pro", systemImage: "sparkles")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.triageVolt)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    }

                    Button(action: restorePurchases) {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                            Spacer()
                            if isRestoring {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isRestoring)

                    Button(action: openAppleSubscriptions) {
                        HStack {
                            Label("Manage Subscription", systemImage: "person.crop.circle")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    if let msg = restoreStatusMessage {
                        Text(msg)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Subscription")
                }

                // MARK: - 2. Help & Support
                Section {
                    NavigationLink(destination: FAQView()) {
                        Label("Frequently Asked Questions", systemImage: "questionmark.circle.fill")
                    }

                    Button(action: reportThreat) {
                        HStack {
                            Label("Report Threat / False Positive", systemImage: "flag.fill")
                                .foregroundColor(.orange)
                            Spacer()
                            Image(systemName: "envelope.fill")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    Button(action: contactSupport) {
                        HStack {
                            Label("Contact Security Support", systemImage: "envelope")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    ShareLink(
                        item: URL(string: "https://sumanxcodes.github.io/triage")!,
                        subject: Text("Triage: Privacy-First iOS Threat Shield"),
                        message: Text("Check out Triage — an on-device smishing and phishing blocker for iPhone.")
                    ) {
                        HStack {
                            Label("Share Triage with Friends", systemImage: "square.and.arrow.up")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            hasCompletedOnboarding = false
                        }
                    }) {
                        HStack {
                            Label("Replay Welcome Tour", systemImage: "sparkles")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                } header: {
                    Text("Help & Support")
                }

                // MARK: - 3. Privacy & Legal
                Section {
                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Label("Privacy Policy & Zero-Telemetry", systemImage: "lock.shield.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    Button(action: { showingTermsOfService = true }) {
                        HStack {
                            Label("Terms of Service (EULA)", systemImage: "doc.text.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                } header: {
                    Text("Privacy & Legal")
                }

                // MARK: - 4. About Triage
                Section {
                    HStack(spacing: 14) {
                        TriageLogoView(size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Triage")
                                .font(.headline)
                            Text("Privacy-First Threat Defense")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("On-Device SQLite O(1)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Triage Security • Zero Tracking • 100% On-Device Privacy")
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
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

// MARK: - Dedicated FAQ View

struct FAQView: View {
    private struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
        let icon: String
    }

    private let faqs: [FAQItem] = [
        FAQItem(
            question: "Can Triage read my private texts or bank OTPs?",
            answer: "No. Apple's IdentityLookup sandbox strictly isolates messages. Messages from your saved Contacts are completely bypassed and never routed to Triage. For unknown senders, Triage only extracts link URLs and checks cryptographic SHA-256 hashes locally on-device. Message text, sender phone numbers, and bank 2FA codes are never stored, logged, or sent to any server.",
            icon: "lock.shield"
        ),
        FAQItem(
            question: "Does the Safari extension track my browsing history?",
            answer: "Never. The Triage Safari Extension runs strictly within WebKit's sandbox. It evaluates domain candidate hashes against the local SQLite database in under 1 millisecond. Your browsing history, visited tabs, search queries, and form inputs never leave your device.",
            icon: "safari"
        ),
        FAQItem(
            question: "Why do I need to enable Triage manually in Settings?",
            answer: "Apple's security architecture gives you total control over extensions. iOS prohibits apps from silently turning on filters in the background. You must grant permission manually in Settings > Messages and Settings > Safari.",
            icon: "gear"
        ),
        FAQItem(
            question: "Does Triage protect me offline in Airplane Mode?",
            answer: "Yes, 100%. The entire threat intelligence database is stored on your device in an optimized SQLite database with WAL indexing. Incoming SMS and Safari links are protected even with no Wi-Fi or cellular connection.",
            icon: "airplane"
        ),
        FAQItem(
            question: "What is Gemini Zero-Day AI protection?",
            answer: "For Triage Pro subscribers, brand-new evasive threats not yet listed in global threat feeds undergo real-time Google Gemini visual and structural inspection. This stops brand mimicry, deceptive login forms, and credential harvesters on day zero.",
            icon: "sparkles"
        )
    ]

    var body: some View {
        List {
            ForEach(faqs) { item in
                Section {
                    Text(item.answer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Label(item.question, systemImage: item.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy & Zero-Telemetry Sheet

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Crest
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.triageVoltSubtle)
                                .frame(width: 48, height: 48)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.triageVolt)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacy Policy")
                                .font(.title2.bold())
                            Text("Zero-Telemetry Guarantee • Audited Apple Manifest")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)

                    Divider()

                    policySection(
                        title: "1. Zero-Telemetry Architecture",
                        body: "Triage is built on a strict privacy model: zero accounts required (no email, password, or sign-in), zero analytics SDKs (no tracking, profiling, or ads), and zero telemetry transmitted during SMS or web evaluation."
                    )

                    policySection(
                        title: "2. SMS Message Filtering (IdentityLookup)",
                        body: "Under Apple's IdentityLookup API, messages from people saved in your Contacts are NEVER routed to Triage. When an unknown message is received, Triage extracts link URLs and calculates cryptographic SHA-256 hashes locally. The text of your messages, sender phone numbers, and any two-factor verification codes are NEVER stored, transmitted, or logged."
                    )

                    policySection(
                        title: "3. Safari Web Shield",
                        body: "The Triage Safari Extension evaluates website URLs using on-device SQLite lookups in under 1 millisecond. Your browsing history, visited URLs, bookmarks, and search queries are never uploaded or retained."
                    )

                    policySection(
                        title: "4. Network Communications",
                        body: "The only network communication performed by Triage is anonymous, scheduled delta syncs to download the latest cryptographic threat hashes from our verified security feeds. These requests contain no device identifiers or personal information."
                    )

                    policySection(
                        title: "5. Apple Privacy Manifest Compliance",
                        body: "Triage includes an audited Apple Privacy Manifest (PrivacyInfo.xcprivacy) declaring zero tracking and zero collected data types across all targets."
                    )
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Terms of Service Sheet

struct TermsOfServiceSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Terms of Service")
                        .font(.title2.bold())

                    Text("Standard Apple EULA & Subscription Terms")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    termsSection(
                        title: "1. Acceptance of Terms",
                        body: "By downloading, installing, or using Triage, you agree to be bound by these Terms of Service and Apple's Standard Licensed Application End User License Agreement (EULA)."
                    )

                    termsSection(
                        title: "2. Security & Threat Intelligence",
                        body: "Triage provides on-device smishing and phishing interception based on verified threat intelligence feeds and heuristic analysis. While Triage strives for highest accuracy, no cybersecurity tool can guarantee 100% prevention of all emerging attacks. Users are advised to exercise vigilance."
                    )

                    termsSection(
                        title: "3. Subscriptions & Billing",
                        body: "Triage Pro is offered as an auto-renewing subscription through Apple In-App Purchase. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing cycle in your Apple ID Account Settings."
                    )

                    termsSection(
                        title: "4. Permitted Use",
                        body: "You may use Triage strictly for personal or internal organizational device protection. Reverse engineering, decompiling, or attempting to compromise the security mechanisms of Triage is strictly prohibited."
                    )

                    termsSection(
                        title: "5. Limitation of Liability",
                        body: "To the maximum extent permitted by applicable law, Triage and its developers shall not be liable for any indirect, incidental, or consequential damages arising from the use of or inability to use the service."
                    )
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func termsSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
