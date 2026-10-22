import SwiftUI

// MARK: - Module Types & Status Models

enum ModuleType: Identifiable {
    case sms
    case safari

    var id: String {
        switch self {
        case .sms: return "sms"
        case .safari: return "safari"
        }
    }
}

enum ModuleStatus {
    case active(Date)
    case ready
    case setupNeeded

    var badgeText: String {
        switch self {
        case .active: return "Active"
        case .ready: return "Ready"
        case .setupNeeded: return "Setup Needed"
        }
    }

    var badgeColor: Color {
        switch self {
        case .active: return .green
        case .ready: return .blue
        case .setupNeeded: return .orange
        }
    }
}

struct ContentView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingOnboarding = false
    @State private var showingPaywall = false
    @State private var selectedModule: ModuleType?
    @State private var threatCount = ThreatDatabase.shared.count()
    @State private var isSyncing = false
    @State private var syncStatusMessage: String?

    // Extension & Configuration State
    @State private var lastSMSDate: Date?
    @State private var lastSafariDate: Date?
    @State private var isSMSConfigured: Bool = false
    @State private var isSafariConfigured: Bool = false

    // MARK: - Dynamic Module Status

    private var smsStatus: ModuleStatus {
        if let date = lastSMSDate {
            return .active(date)
        } else if isSMSConfigured {
            return .ready
        } else {
            return .setupNeeded
        }
    }

    private var safariStatus: ModuleStatus {
        if let date = lastSafariDate {
            return .active(date)
        } else if isSafariConfigured {
            return .ready
        } else {
            return .setupNeeded
        }
    }

    private var smsSubtitle: String {
        switch smsStatus {
        case .active(let date):
            return "Verified active • \(formattedRelativeDate(date))"
        case .ready:
            return "Standing by in Messages"
        case .setupNeeded:
            return "Requires activation in Settings"
        }
    }

    private var safariSubtitle: String {
        switch safariStatus {
        case .active(let date):
            return "Verified active • \(formattedRelativeDate(date))"
        case .ready:
            return "Standing by in Safari"
        case .setupNeeded:
            return "Requires activation in Settings"
        }
    }

    private var isFullyProtected: Bool {
        let smsOk = isModuleProtected(smsStatus)
        let safariOk = isModuleProtected(safariStatus)
        return smsOk && safariOk
    }

    private var isPartiallyProtected: Bool {
        let smsOk = isModuleProtected(smsStatus)
        let safariOk = isModuleProtected(safariStatus)
        return (smsOk && !safariOk) || (!smsOk && safariOk)
    }

    private func isModuleProtected(_ status: ModuleStatus) -> Bool {
        switch status {
        case .active, .ready: return true
        case .setupNeeded: return false
        }
    }

    private var heroTitle: String {
        if isFullyProtected {
            return "Protection Active"
        } else if isPartiallyProtected {
            return "Partial Protection"
        } else {
            return "Setup Required"
        }
    }

    private var heroSubtitle: String {
        if isFullyProtected {
            return "Dual-layer on-device SMS & Safari protection."
        } else if isPartiallyProtected {
            return "One or more security modules require setup."
        } else {
            return "Enable SMS & Safari protection in iOS Settings."
        }
    }

    private var heroGradient: LinearGradient {
        if subscriptionManager.isProUser {
            return LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if isFullyProtected {
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isPartiallyProtected {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var heroIcon: String {
        if isFullyProtected {
            return subscriptionManager.isProUser ? "shield.checkered" : "shield.lefthalf.filled.badge.checkmark"
        } else if isPartiallyProtected {
            return "shield.lefthalf.filled"
        } else {
            return "shield.slash.fill"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: - Hero Protection Status
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(heroGradient)
                                .frame(width: 80, height: 80)

                            Image(systemName: heroIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 42, height: 42)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)

                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Text(heroTitle)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                if subscriptionManager.isProUser {
                                    Text("PRO")
                                        .font(.system(size: 10, weight: .heavy))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }

                            Text(heroSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 2)

                    // MARK: - Active Modules Section
                    VStack(spacing: 0) {
                        moduleRow(
                            type: .sms,
                            icon: "message.badge.filled.fill",
                            iconColor: .green,
                            title: "SMS Smishing Filter",
                            subtitle: smsSubtitle,
                            status: smsStatus
                        )

                        Divider()
                            .padding(.leading, 56)

                        moduleRow(
                            type: .safari,
                            icon: "safari.fill",
                            iconColor: .blue,
                            title: "Safari Extension",
                            subtitle: safariSubtitle,
                            status: safariStatus
                        )
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    // MARK: - Threat Intelligence Card
                    VStack(spacing: 14) {
                        HStack {
                            Label("Offline Threat Database", systemImage: "internaldrive.fill")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(threatCount) Active")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Updated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let lastSync = ThreatSyncManager.shared.lastSyncDate {
                                    Text("\(lastSync, style: .relative) ago")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("Never")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }

                            Spacer()

                            Button(action: triggerSync) {
                                HStack(spacing: 5) {
                                    if isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Sync")
                                    }
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .disabled(isSyncing)
                        }

                        if let msg = syncStatusMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(msg)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    // MARK: - Triage Pro Banner (if Free) or Pro Active Card (if Pro)
                    if !subscriptionManager.isProUser {
                        Button(action: { showingPaywall = true }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "sparkles")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Triage Pro")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Unlock Gemini Zero-Day AI & hourly sync")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.85))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(14)
                            .background(
                                LinearGradient(
                                    colors: [.indigo, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Triage Pro Active")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Zero-Day Gemini AI and continuous sync enabled.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .navigationTitle("Triage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingOnboarding = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.body)
                    }
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $selectedModule) { module in
                ModuleDetailSheet(moduleType: module, onDismiss: {
                    refreshView()
                })
            }
            .onAppear {
                refreshView()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    refreshView()
                }
            }
        }
    }

    // MARK: - Subviews

    private func moduleRow(
        type: ModuleType,
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        status: ModuleStatus
    ) -> some View {
        Button(action: { selectedModule = type }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(status.badgeColor)
                        .frame(width: 7, height: 7)
                    Text(status.badgeText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(status.badgeColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.badgeColor.opacity(0.12))
                .cornerRadius(6)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private func refreshView() {
        threatCount = ThreatDatabase.shared.count()
        let state = AppGroup.loadState()
        if let ts = state.lastSMSEvaluation, ts > 0 {
            lastSMSDate = Date(timeIntervalSince1970: ts)
        } else {
            lastSMSDate = nil
        }
        if let ts = state.lastSafariEvaluation, ts > 0 {
            lastSafariDate = Date(timeIntervalSince1970: ts)
        } else {
            lastSafariDate = nil
        }
        isSMSConfigured = state.isSMSConfigured
        isSafariConfigured = state.isSafariConfigured
    }

    private func formattedRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func triggerSync() {
        isSyncing = true
        syncStatusMessage = nil
        Task {
            do {
                let result = try await ThreatSyncManager.shared.sync()
                await MainActor.run {
                    threatCount = ThreatDatabase.shared.count()
                    syncStatusMessage = "Sync complete: +\(result.added) added, -\(result.removed) removed"
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
}

// MARK: - Module Detail Sheet

struct ModuleDetailSheet: View {
    let moduleType: ModuleType
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var isConfigured: Bool = false
    @State private var lastHeartbeatDate: Date?
    @State private var testPromptMessage: String?

    private var moduleTitle: String {
        switch moduleType {
        case .sms: return "SMS Smishing Filter"
        case .safari: return "Safari Extension"
        }
    }

    private var moduleIcon: String {
        switch moduleType {
        case .sms: return "message.badge.filled.fill"
        case .safari: return "safari.fill"
        }
    }

    private var moduleColor: Color {
        switch moduleType {
        case .sms: return .green
        case .safari: return .blue
        }
    }

    private var moduleDescription: String {
        switch moduleType {
        case .sms:
            return "Analyzes incoming SMS messages from unknown senders on-device using high-speed SQLite hash matching."
        case .safari:
            return "Intercepts malicious web links and phishing pages inside Safari before malicious code or login forms execute."
        }
    }

    private var currentStatus: ModuleStatus {
        if let date = lastHeartbeatDate {
            return .active(date)
        } else if isConfigured {
            return .ready
        } else {
            return .setupNeeded
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(moduleColor.opacity(0.15))
                                    .frame(width: 48, height: 48)

                                Image(systemName: moduleIcon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(moduleColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(moduleTitle)
                                    .font(.title3)
                                    .fontWeight(.bold)

                                Text(moduleDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }

                        Divider()

                        HStack {
                            Text("Current Status")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()

                            HStack(spacing: 5) {
                                Circle()
                                    .fill(currentStatus.badgeColor)
                                    .frame(width: 8, height: 8)
                                Text(currentStatus.badgeText)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(currentStatus.badgeColor)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(currentStatus.badgeColor.opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Configuration Toggle Card
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { isConfigured },
                            set: { newValue in
                                isConfigured = newValue
                                updateConfiguration(newValue)
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enabled in iOS Settings")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Reflects whether you switched this on in Settings")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(moduleColor)

                        Divider()

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: statusInfoIcon)
                                .foregroundColor(currentStatus.badgeColor)
                                .font(.footnote)
                                .padding(.top, 1)

                            Text(statusInfoText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Action Buttons
                    VStack(spacing: 10) {
                        Button(action: openSettings) {
                            HStack(spacing: 8) {
                                Image(systemName: "gear")
                                    .font(.body.weight(.semibold))
                                Text("Open iOS Settings")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 22)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        if moduleType == .safari {
                            Button(action: testInSafari) {
                                HStack(spacing: 8) {
                                    Image(systemName: "safari")
                                        .font(.body.weight(.semibold))
                                    Text("Test in Safari")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 22)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        if let msg = testPromptMessage {
                            Text(msg)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 8)
                        }
                    }

                    // Setup Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Configure")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Divider()

                        if moduleType == .sms {
                            stepRow(number: "1", text: "Open **Settings** > **Apps** > **Messages**")
                            stepRow(number: "2", text: "Tap **Unknown & Spam**")
                            stepRow(number: "3", text: "Turn ON **Filter Unknown Senders**")
                            stepRow(number: "4", text: "Under SMS Filtering, select **Triage** and tap **Enable**")
                        } else {
                            stepRow(number: "1", text: "Open **Settings** > **Safari** (or **Apps** > **Safari**)")
                            stepRow(number: "2", text: "Tap **Extensions**")
                            stepRow(number: "3", text: "Turn ON **Triage Security**")
                            stepRow(number: "4", text: "Under Permissions, select **All Websites** > **Always Allow**")
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Apple Privacy Notice
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                            .padding(.top, 1)

                        Text("**Apple Privacy Isolation:** iOS sandboxes extensions so third-party apps cannot inspect your system Settings toggles. Triage verifies status through private on-device App Group heartbeats without transmitting personal data.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle(moduleTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss?()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadState()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    loadState()
                }
            }
        }
    }

    private var statusInfoIcon: String {
        switch currentStatus {
        case .active: return "checkmark.circle.fill"
        case .ready: return "clock.fill"
        case .setupNeeded: return "exclamationmark.circle.fill"
        }
    }

    private var statusInfoText: String {
        switch currentStatus {
        case .active(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            let rel = formatter.localizedString(for: date, relativeTo: Date())
            return "Verified active (\(rel)) via on-device extension."
        case .ready:
            return "Marked as enabled. Standing by for incoming events."
        case .setupNeeded:
            return "Disabled. Open iOS Settings to activate this module."
        }
    }

    private func stepRow(number: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(number)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
                .background(Color(.systemFill))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func loadState() {
        let state = AppGroup.loadState()
        switch moduleType {
        case .sms:
            isConfigured = state.isSMSConfigured
            if let ts = state.lastSMSEvaluation, ts > 0 {
                lastHeartbeatDate = Date(timeIntervalSince1970: ts)
            } else {
                lastHeartbeatDate = nil
            }
        case .safari:
            isConfigured = state.isSafariConfigured
            if let ts = state.lastSafariEvaluation, ts > 0 {
                lastHeartbeatDate = Date(timeIntervalSince1970: ts)
            } else {
                lastHeartbeatDate = nil
            }
        }
    }

    private func updateConfiguration(_ enabled: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch moduleType {
        case .sms:
            AppGroup.isSMSConfiguredByUser = enabled
            if !enabled {
                AppGroup.clearSMSHeartbeat()
                lastHeartbeatDate = nil
            }
        case .safari:
            AppGroup.isSafariConfiguredByUser = enabled
            if !enabled {
                AppGroup.clearSafariHeartbeat()
                lastHeartbeatDate = nil
            }
        }
    }

    private func openSettings() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func testInSafari() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        testPromptMessage = "Safari opened! If Triage is enabled in Settings, the extension will send a heartbeat. Switch back to verify."
        if let url = URL(string: "https://example.com") {
            UIApplication.shared.open(url)
        }
    }
}
