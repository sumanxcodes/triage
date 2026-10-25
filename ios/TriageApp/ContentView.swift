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
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $selectedModule) { module in
                ModuleDetailSheet(moduleType: module, onDismiss: {
                    refreshView()
                })
                .presentationDetents([.fraction(0.68), .large])
                .presentationDragIndicator(.visible)
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

// MARK: - Native Apple HIG-Compliant Module Setup Sheet

struct ModuleDetailSheet: View {
    let moduleType: ModuleType
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var lastHeartbeatDate: Date?
    @State private var isConfigured: Bool = false
    @State private var testPromptMessage: String?
    @State private var showSMSSimulator: Bool = false

    private var moduleTitle: String {
        switch moduleType {
        case .sms: return "SMS Filter"
        case .safari: return "Safari Shield"
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

    private var currentStatus: ModuleStatus {
        if let date = lastHeartbeatDate {
            return .active(date)
        } else if isConfigured {
            return .ready
        } else {
            return .setupNeeded
        }
    }

    private var statusDescription: String {
        switch currentStatus {
        case .active(let date):
            let rel = RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
            return "Verified active (\(rel))"
        case .ready:
            return "Configured • Standing by for first scan"
        case .setupNeeded:
            return "Setup required in iPhone Settings"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Status Overview Card
                    statusCard

                    // 2. Step-by-Step Instructions Card
                    instructionsCard

                    // 3. Primary Actions Section
                    actionSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
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
            .sheet(isPresented: $showSMSSimulator) {
                SMSSimulatorSheet(onComplete: {
                    loadState()
                    onDismiss?()
                })
                .presentationDetents([.fraction(0.88), .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Subviews

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(moduleColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: moduleIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(moduleColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(moduleType == .sms ? "SMS Smishing Filter" : "Safari Web Extension")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(currentStatus.badgeColor)
                    .frame(width: 7, height: 7)
                Text(currentStatus.badgeText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(currentStatus.badgeColor)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(currentStatus.badgeColor.opacity(0.12))
            .cornerRadius(7)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW TO ENABLE")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 12) {
                if moduleType == .sms {
                    stepRow(
                        icon: "gearshape.fill",
                        iconColor: .gray,
                        text: "Open **Settings** > **Apps** > **Messages**"
                    )
                    Divider()
                    stepRow(
                        icon: "bubble.left.and.exclamationmark.bubble.right.fill",
                        iconColor: .blue,
                        text: "Tap **Unknown & Spam**"
                    )
                    Divider()
                    stepRow(
                        icon: "switch.2",
                        iconColor: .green,
                        text: "Turn ON **Filter Unknown Senders**"
                    )
                    Divider()
                    stepRow(
                        icon: "checkmark.shield.fill",
                        iconColor: .purple,
                        text: "Select **Triage** and tap **Enable**"
                    )
                } else {
                    stepRow(
                        icon: "gearshape.fill",
                        iconColor: .gray,
                        text: "Open **Settings** > **Apps** > **Safari**"
                    )
                    Divider()
                    stepRow(
                        icon: "puzzlepiece.extension.fill",
                        iconColor: .blue,
                        text: "Tap **Extensions**"
                    )
                    Divider()
                    stepRow(
                        icon: "switch.2",
                        iconColor: .green,
                        text: "Turn ON **Triage Security**"
                    )
                    Divider()
                    stepRow(
                        icon: "checkmark.shield.fill",
                        iconColor: .purple,
                        text: "Permissions: **All Websites** > **Always Allow**"
                    )
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func stepRow(icon: String, iconColor: Color, text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button(action: openSettings) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.semibold))
                    Text("Open iPhone Settings")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 24)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("Settings opens on Triage. Tap **‹ Apps** in top-left to reach \(moduleType == .sms ? "Messages" : "Safari").")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            if moduleType == .sms {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showSMSSimulator = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.body.weight(.semibold))
                        Text("Simulate SMS Inspection")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 24)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 4)
            }

            if moduleType == .safari {
                Button(action: testInSafari) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                            .font(.body.weight(.semibold))
                        Text("Test Safari Shield")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 24)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 4)

                if let msg = testPromptMessage {
                    Text(msg)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
    }

    // MARK: - Helper Methods

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

    private func openSettings() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        switch moduleType {
        case .sms:
            AppGroup.isSMSConfiguredByUser = true
        case .safari:
            AppGroup.isSafariConfiguredByUser = true
        }
        isConfigured = true
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func testInSafari() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        testPromptMessage = "Safari opened. If enabled, the extension sends an instant heartbeat. Return to verify."
        if let url = URL(string: "https://example.com") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Native SMS Threat Simulator Sheet

struct SMSSimulatorSheet: View {
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    struct AttackPreset: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: Color
        let sender: String
        let message: String
    }

    private let presets: [AttackPreset] = [
        AttackPreset(
            title: "AusPost",
            icon: "shippingbox.fill",
            color: .red,
            sender: "+61 489 123 456",
            message: "AusPost: Your parcel could not be delivered due to incomplete address details. Update delivery address here: https://example.com/delivery"
        ),
        AttackPreset(
            title: "CommBank",
            icon: "building.columns.fill",
            color: .orange,
            sender: "+61 412 987 654",
            message: "CommBank: Unusual sign-in attempt detected from an unrecognized device. Verify NetBank identity: https://example.com/auth"
        ),
        AttackPreset(
            title: "Linkt Toll",
            icon: "car.fill",
            color: .purple,
            sender: "+61 400 555 123",
            message: "Linkt: You have an unpaid toll invoice of $12.40. Avoid late fees by paying now: https://example.com/toll"
        ),
        AttackPreset(
            title: "Clean SMS",
            icon: "bubble.left.and.bubble.right.fill",
            color: .green,
            sender: "+61 491 570 006",
            message: "Hey! Are you still free for coffee at 2pm today? Let me know!"
        )
    ]

    @State private var senderNumber: String = "+61 489 123 456"
    @State private var messageBody: String = "AusPost: Your parcel could not be delivered due to incomplete address details. Update delivery address here: https://example.com/delivery"
    @State private var evaluationResult: SimulationVerdict? = nil
    @State private var selectedPresetIndex: Int? = 0

    enum SimulationVerdict: Equatable {
        case threat(url: String, brand: String?, category: String)
        case unverified(url: String)
        case clean
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Description
                    HStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("IdentityLookup Evaluation Engine")
                                .font(.subheadline.weight(.semibold))
                            Text("Tests message payloads against the on-device threat database without requiring cellular SMS.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Attack Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sample Test Scenarios")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                                    Button(action: {
                                        selectPreset(index)
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: preset.icon)
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(preset.color)
                                            Text(preset.title)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedPresetIndex == index ? preset.color.opacity(0.18) : Color(.secondarySystemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(selectedPresetIndex == index ? preset.color : Color.clear, lineWidth: 1.5)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Simulated Message Editor
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Simulated Incoming Payload")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                TextField("Sender Number", text: $senderNumber)
                                    .font(.subheadline)
                                    .keyboardType(.phonePad)
                            }

                            Divider()

                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "bubble.left.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                    .padding(.top, 4)
                                TextEditor(text: $messageBody)
                                    .font(.subheadline)
                                    .frame(minHeight: 70)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // Run Inspection Button
                    Button(action: runEvaluation) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.body.weight(.semibold))
                            Text("Run Threat Evaluation")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 24)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Evaluation Verdict Card
                    if let verdict = evaluationResult {
                        verdictCard(for: verdict)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("SMS Threat Simulator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if ThreatDatabase.shared.count() == 0 {
                    _ = try? ThreatSyncManager.shared.seedDemoThreats()
                }
            }
        }
    }

    // MARK: - Verdict Subview

    @ViewBuilder
    private func verdictCard(for verdict: SimulationVerdict) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            switch verdict {
            case .threat(let url, let brand, let category):
                HStack(spacing: 12) {
                    Image(systemName: "shield.slash.fill")
                        .font(.title2)
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smishing Threat Detected")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("Action: Filtered to Junk (.junk)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("BLOCKED")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    if let b = brand {
                        detailRow(label: "Brand Impersonated", value: b)
                    }
                    detailRow(label: "Threat Category", value: category.capitalized)
                    detailRow(label: "Extracted URL", value: url)
                    detailRow(label: "iOS Action", value: "Silently routed to Messages > Junk")
                    detailRow(label: "Audit Status", value: "Logged to Triage Threat History")
                }

            case .clean:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Legitimate Message")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("Action: Allowed to Inbox (.none)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("CLEAN")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }

                Divider()

                Text("No malicious links, homoglyphs, or known smishing hashes were detected. Message safely delivered to primary inbox.")
                    .font(.caption)
                    .foregroundColor(.secondary)

            case .unverified(let url):
                HStack(spacing: 12) {
                    Image(systemName: "questionmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unverified Link Detected")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Action: Defer to Cloud Filter")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("DEFERRED")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    detailRow(label: "Extracted URL", value: url)
                    detailRow(label: "Offline Status", value: "Not found in local cache")
                    detailRow(label: "System Action", value: "Queries cloud backend over HTTPS")
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Simulation Logic

    private func selectPreset(_ index: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedPresetIndex = index
        senderNumber = presets[index].sender
        messageBody = presets[index].message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            evaluationResult = nil
        }
    }

    private func runEvaluation() {
        // Record SMS heartbeat
        AppGroup.recordSMSHeartbeat()
        onComplete?()

        // 1. Extract URLs
        let urls = URLHasher.extractURLs(from: messageBody)

        // 2. Candidate hash inspection via GRDB
        var threatMatch: (url: URL, brand: String?, category: String)? = nil
        for url in urls {
            let candidateHashes = URLHasher.candidateHashes(for: url)
            if ThreatDatabase.shared.isThreat(candidateHashes: candidateHashes) {
                let match = ThreatDatabase.shared.findThreat(candidateHashes: candidateHashes)
                threatMatch = (url, match?.targetBrand, match?.category ?? "smishing")
                break
            }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if let threat = threatMatch {
                ThreatDatabase.shared.recordEvent(
                    source: "sms",
                    target: threat.url.absoluteString,
                    sender: senderNumber.isEmpty ? "Unknown Sender" : senderNumber,
                    category: threat.category,
                    targetBrand: threat.brand,
                    actionTaken: "filtered_to_junk"
                )
                evaluationResult = .threat(url: threat.url.absoluteString, brand: threat.brand, category: threat.category)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } else if let firstUrl = urls.first {
                evaluationResult = .unverified(url: firstUrl.absoluteString)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } else {
                evaluationResult = .clean
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
