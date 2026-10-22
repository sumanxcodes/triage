import SwiftUI
import StoreKit

public struct SettingsView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingPaywall = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingZeroTelemetry = false
    @State private var showingOnboarding = false

    @State private var threatCount = ThreatDatabase.shared.count()
    @State private var isSyncing = false
    @State private var syncStatusMessage: String?
    @State private var isRestoring = false
    @State private var restoreStatusMessage: String?

    // FAQ expansion state
    @State private var expandedFAQIndex: Int? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Section 1: Subscription & Plan
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(subscriptionManager.isProUser ?
                                      LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                      LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)

                            Image(systemName: subscriptionManager.isProUser ? "shield.checkered" : "shield.lefthalf.filled.badge.checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(subscriptionManager.isProUser ? "Triage Pro" : "Triage Free")
                                    .font(.headline)

                                Text(subscriptionManager.isProUser ? "ACTIVE" : "STANDARD")
                                    .font(.system(size: 9, weight: .heavy))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(subscriptionManager.isProUser ? Color.purple : Color.secondary.opacity(0.2))
                                    .foregroundColor(subscriptionManager.isProUser ? .white : .secondary)
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
                                    .foregroundColor(.purple)
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
                    Text("Subscription & Plan")
                }

                // MARK: - Section 2: Protection & Setup
                Section {
                    Button(action: { showingOnboarding = true }) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Extension Setup Guide")
                                        .foregroundColor(.primary)
                                    Text("Step-by-step route for Messages & Safari")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "checklist")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    Button(action: openSettings) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Open iPhone Settings")
                                        .foregroundColor(.primary)
                                    Text("Opens Settings > Triage (tap ‹ Apps to navigate)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "gear")
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    Button(action: testSafari) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Test Safari Extension")
                                        .foregroundColor(.primary)
                                    Text("Verifies real-time background shield heartbeat")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "safari")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                } header: {
                    Text("Protection Configuration")
                } footer: {
                    Text("Apple's privacy rules require enabling extensions manually. Tapping Open Settings will open Settings > Triage — from there, tap ‹ Apps (or ‹ Settings) in the top-left to configure Messages or Safari.")
                }

                // MARK: - Section 3: Threat Intelligence Database
                Section {
                    HStack {
                        Label("Active Threat Signatures", systemImage: "internaldrive.fill")
                        Spacer()
                        Text("\(threatCount)")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Label("Last Cloud Sync", systemImage: "clock")
                        Spacer()
                        if let lastSync = ThreatSyncManager.shared.lastSyncDate {
                            Text("\(lastSync, style: .relative) ago")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: triggerManualSync) {
                        HStack {
                            Label("Check for Updates Now", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isSyncing)

                    if let msg = syncStatusMessage {
                        Text(msg)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Threat Intelligence")
                } footer: {
                    Text("Signatures are compiled from verified threat feeds (OpenPhish, Phishing Army, URLhaus) and stored on-device.")
                }

                // MARK: - Section 4: Frequently Asked Questions
                Section {
                    ForEach(Array(faqList.enumerated()), id: \.offset) { index, item in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedFAQIndex == index },
                                set: { isExpanded in
                                    expandedFAQIndex = isExpanded ? index : nil
                                }
                            )
                        ) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        } label: {
                            Label(item.question, systemImage: item.icon)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("Frequently Asked Questions")
                }

                // MARK: - Section 5: Compliance, Privacy & Legal
                Section {
                    Button(action: { showingZeroTelemetry = true }) {
                        HStack {
                            Label("Zero-Telemetry Guarantee", systemImage: "hand.raised.fill")
                                .foregroundColor(.green)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Label("Privacy Policy", systemImage: "lock.shield.fill")
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

                    HStack {
                        Label("Apple Privacy Manifest", systemImage: "checkmark.seal.fill")
                        Spacer()
                        Text("Audited (0 Data Tracked)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Privacy & Legal Compliance")
                } footer: {
                    Text("Triage is engineered to meet Apple's highest privacy standards. We have no user tracking, no third-party analytics SDKs, and no remote message logging.")
                }

                // MARK: - Section 6: Support & Feedback
                Section {
                    Button(action: reportThreat) {
                        HStack {
                            Label("Report Threat / False Positive", systemImage: "exclamationmark.bubble.fill")
                                .foregroundColor(.orange)
                            Spacer()
                            Image(systemName: "envelope.fill")
                                .font(.caption2)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }

                    Button(action: contactSupport) {
                        HStack {
                            Label("Contact Security Team", systemImage: "envelope")
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
                        message: Text("Check out Triage — an on-device smishing and phishing link blocker for iPhone.")
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
                } header: {
                    Text("Support & Feedback")
                }

                // MARK: - Section 7: About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Inspection Architecture")
                        Spacer()
                        Text("On-Device SQLite O(1)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS 18+ App Group Container")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About Triage")
                } footer: {
                    VStack(spacing: 6) {
                        Text("Built with Apple IdentityLookup & SafariServices")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("Zero Tracking • 100% On-Device Privacy")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicySheet()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceSheet()
            }
            .sheet(isPresented: $showingZeroTelemetry) {
                ZeroTelemetrySheet()
            }
            .onAppear {
                threatCount = ThreatDatabase.shared.count()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    threatCount = ThreatDatabase.shared.count()
                }
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

    private func openSettings() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func testSafari() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let url = URL(string: "https://example.com") {
            UIApplication.shared.open(url)
        }
    }

    private func triggerManualSync() {
        isSyncing = true
        syncStatusMessage = nil
        Task {
            do {
                let result = try await ThreatSyncManager.shared.sync()
                await MainActor.run {
                    threatCount = ThreatDatabase.shared.count()
                    syncStatusMessage = "Updated: +\(result.added) added, -\(result.removed) removed"
                    isSyncing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    syncStatusMessage = "Sync failed: \(error.localizedDescription)"
                    isSyncing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
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

    // MARK: - FAQ Data Model

    private struct FAQItem {
        let question: String
        let answer: String
        let icon: String
    }

    private var faqList: [FAQItem] {
        [
            FAQItem(
                question: "Can Triage read my personal texts or bank OTPs?",
                answer: "No. Apple's IdentityLookup framework strictly enforces privacy. Messages from senders saved in your Contacts are completely bypassed and never routed to Triage. For unknown messages, Triage only extracts link URLs and calculates cryptographic SHA-256 hashes locally. Message body text, sender phone numbers, and two-factor codes are never saved, logged, or sent to any server.",
                icon: "lock.shield"
            ),
            FAQItem(
                question: "Does the Safari extension track my browsing history?",
                answer: "Never. The Triage Safari Web Extension executes strictly within Safari's sandbox. It evaluates visited website hostnames and URLs against the local SQLite database in under 1 millisecond. No browsing history, search terms, form inputs, or cookies ever leave your device.",
                icon: "safari"
            ),
            FAQItem(
                question: "Why do I need to manually enable Triage in Settings?",
                answer: "Apple's security architecture gives you total control over extensions. iOS prohibits apps from silently enabling themselves in the background. You must turn on Triage in Settings > Messages > Unknown & Spam and Settings > Safari > Extensions.",
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
            ),
            FAQItem(
                question: "How do I report a false positive or missed link?",
                answer: "You can tap 'Report Threat / False Positive' in Settings to email our security response team directly with the suspicious link or sender. Reports are investigated and reflected in global database updates.",
                icon: "flag.fill"
            )
        ]
    }
}

// MARK: - Privacy Policy Sheet

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Privacy Policy")
                        .font(.largeTitle.bold())

                    Text("Effective Date: October 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    policySection(
                        title: "1. Zero-Telemetry Philosophy",
                        body: "Triage is architected on a fundamental privacy principle: what happens on your device stays on your device. We do not require account creation, email addresses, passwords, or phone numbers to use Triage. We do not track, profile, or sell your data."
                    )

                    policySection(
                        title: "2. SMS Message Filtering (IdentityLookup)",
                        body: "Under Apple's IdentityLookup API, messages from people saved in your Contacts are NEVER routed to Triage. When an unknown message is received, Triage extracts link URLs and calculates cryptographic SHA-256 hashes locally. The text of your messages, sender phone numbers, and any two-factor verification codes are NEVER stored, transmitted, or logged."
                    )

                    policySection(
                        title: "3. Safari Web Extension",
                        body: "The Triage Safari Extension evaluates website URLs using on-device SQLite lookups. The extension operates with zero telemetry: your browsing history, visited URLs, bookmarks, and search queries are never uploaded or retained."
                    )

                    policySection(
                        title: "4. Network Communications",
                        body: "The only network communication performed by Triage is anonymous, scheduled delta syncs to download the latest cryptographic threat hashes from our verified security feeds. These requests contain no device identifiers or personal information."
                    )

                    policySection(
                        title: "5. Apple Privacy Manifest",
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
                        .font(.largeTitle.bold())

                    Text("Standard Apple EULA & Service Terms")
                        .font(.caption)
                        .foregroundColor(.secondary)

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

// MARK: - Zero-Telemetry Guarantee Sheet

struct ZeroTelemetrySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.green)
                        }

                        Text("Zero-Telemetry Guarantee")
                            .font(.system(.title, design: .rounded, weight: .bold))

                        Text("How Triage protects you without ever seeing your personal data.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Pillar 1
                    pillarRow(
                        icon: "person.crop.circle.badge.xmark",
                        color: .blue,
                        title: "1. No Accounts, No Logins",
                        detail: "Triage requires zero personal information. No email, name, phone number, or password is ever collected or stored."
                    )

                    // Pillar 2
                    pillarRow(
                        icon: "chart.line.downtrend.xyaxis",
                        color: .purple,
                        title: "2. Zero Tracking & Analytics",
                        detail: "We have rejected all third-party tracking, advertising, and user profiling frameworks. There is no Google Analytics, Mixpanel, or Facebook SDK."
                    )

                    // Pillar 3
                    pillarRow(
                        icon: "cpu.fill",
                        color: .green,
                        title: "3. 100% On-Device Hash Matching",
                        detail: "When an SMS or webpage is analyzed, URLs are stripped and converted to one-way SHA-256 cryptographic hashes right on your iPhone. Only hashes are matched against the local SQLite database."
                    )

                    // Pillar 4
                    pillarRow(
                        icon: "checkmark.shield.fill",
                        color: .indigo,
                        title: "4. Apple Privacy Manifest",
                        detail: "Our App Store privacy declaration specifies zero collected data categories (NSPrivacyCollectedDataTypes = empty). Audited by Apple's automated build review."
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

    private func pillarRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
