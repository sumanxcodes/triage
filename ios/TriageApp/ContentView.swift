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
        case .setupNeeded: return "Setup Required"
        }
    }

    var badgeColor: Color {
        switch self {
        case .active: return RetroTheme.textAccent
        case .ready: return .blue
        case .setupNeeded: return RetroTheme.textAmber
        }
    }
}

struct ContentView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingPaywall = false
    @State private var selectedModule: ModuleType?
    @State private var showThreatSimulator = false
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

    private var activeLayersCount: Int {
        var count = 0
        if isModuleProtected(smsStatus) { count += 1 }
        if isModuleProtected(safariStatus) { count += 1 }
        return count
    }

    private var isFullyProtected: Bool {
        activeLayersCount == 2
    }

    private func isModuleProtected(_ status: ModuleStatus) -> Bool {
        switch status {
        case .active, .ready: return true
        case .setupNeeded: return false
        }
    }

    private var statusColor: Color {
        isFullyProtected ? RetroTheme.textAccent : RetroTheme.textAmber
    }

    private var formattedThreatCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: threatCount)) ?? "\(threatCount)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // MARK: - 1. Retro Terminal Brand Header
                        topBar

                        // MARK: - 2. Hero Security Centerpiece
                        heroStatusSection

                        // MARK: - 3. Retro Dual Shield Cards
                        modulesSection

                        // MARK: - 4. Unified Telemetry Dock
                        telemetrySection

                        // MARK: - 5. Threat Simulator Action
                        simulatorButton

                        // MARK: - 6. Pro Membership
                        if !subscriptionManager.isProUser {
                            proBanner
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 96)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
            .sheet(isPresented: $showThreatSimulator) {
                SMSSimulatorSheet(onComplete: {
                    refreshView()
                })
                .presentationDetents([.fraction(0.88), .large])
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

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text("TRIAGE // TERMINAL")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(.primary)
            }

            Spacer()

            if subscriptionManager.isProUser {
                RetroBadge("PRO", color: RetroTheme.textAccent, isFilled: true)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingPaywall = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text("UPGRADE")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(RetroTheme.volt)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(RetroTheme.border, lineWidth: 1.5)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(RetroTheme.shadow)
                            .offset(x: 2, y: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 2)
    }

    private var heroStatusSection: some View {
        RetroCard(cornerRadius: 12) {
            VStack(spacing: 16) {
                HStack {
                    RetroBadge(
                        isFullyProtected ? "SHIELD: ACTIVE" : "SHIELD: INCOMPLETE",
                        color: isFullyProtected ? RetroTheme.textAccent : RetroTheme.textAmber,
                        isFilled: true
                    )

                    Spacer()

                    Text(isFullyProtected ? "[2/2 ONLINE]" : "[\(activeLayersCount)/2 READY]")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 18) {
                    TriageLogoView(size: 64, showsGlow: isFullyProtected)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isFullyProtected ? "SYSTEM SECURED" : "ACTION NEEDED")
                            .font(.system(size: 20, weight: .heavy, design: .monospaced))
                            .foregroundColor(.primary)

                        Text(isFullyProtected ?
                             "SMS smishing filter & Safari web shield actively protecting." :
                             "Turn on shields in iPhone Settings to guard messages & web.")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("DEFENSE INTEGRITY")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(isFullyProtected ? "100%" : "\(activeLayersCount * 50)%")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(isFullyProtected ? RetroTheme.textAccent : RetroTheme.textAmber)
                    }

                    RetroBlockMeter(
                        filled: isFullyProtected ? 16 : (activeLayersCount * 8),
                        total: 16,
                        color: isFullyProtected ? RetroTheme.textAccent : RetroTheme.textAmber
                    )
                }
            }
            .padding(18)
        }
    }

    private var modulesSection: some View {
        VStack(spacing: 14) {
            moduleCard(
                type: .sms,
                icon: "message.badge.filled.fill",
                iconColor: RetroTheme.textAccent,
                title: "SMS FILTER",
                subtitle: "On-Device Message Guard",
                status: smsStatus
            )

            moduleCard(
                type: .safari,
                icon: "safari.fill",
                iconColor: .blue,
                title: "SAFARI SHIELD",
                subtitle: "WebKit Phishing Blocker",
                status: safariStatus
            )
        }
    }

    private func moduleCard(
        type: ModuleType,
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        status: ModuleStatus
    ) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedModule = type
        }) {
            RetroCard(cornerRadius: 10) {
                HStack(spacing: 14) {
                    ZStack {
                        Rectangle()
                            .fill(RetroTheme.elevatedSurface)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Rectangle()
                                    .stroke(RetroTheme.border, lineWidth: 1.5)
                            )

                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(iconColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(.primary)

                        Text(subtitle)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    RetroBadge(
                        status.badgeText,
                        color: isModuleProtected(status) ? RetroTheme.textAccent : RetroTheme.textAmber,
                        isFilled: true
                    )

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }

    private var telemetrySection: some View {
        RetroCard(cornerRadius: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(formattedThreatCount)
                            .font(.system(size: 18, weight: .heavy, design: .monospaced))
                            .foregroundColor(.primary)

                        Text("SIGNATURES")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                    }

                    if let lastSync = ThreatSyncManager.shared.lastSyncDate {
                        Text("SYNCED \(lastSync, style: .relative) AGO // O(1) SQLITE")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        Text("LOCAL SQLITE // CACHE READY")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: triggerSync) {
                    HStack(spacing: 6) {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.black)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .bold))
                        }

                        Text(isSyncing ? "SYNCING" : "SYNC")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    }
                }
                .buttonStyle(RetroButtonStyle(backgroundColor: RetroTheme.volt, foregroundColor: .black, cornerRadius: 6))
                .disabled(isSyncing)
            }
            .padding(14)
        }
    }

    private var simulatorButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showThreatSimulator = true
        }) {
            RetroCard(cornerRadius: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(RetroTheme.textAccent)

                    Text("> TEST THREAT DETECTION")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(.primary)
                        .tracking(0.5)

                    Spacer()

                    RetroBadge("SIM", color: RetroTheme.textAccent, isFilled: false)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }

    private var proBanner: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showingPaywall = true
        }) {
            RetroCard(cornerRadius: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RetroTheme.textAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("UPGRADE TO TRIAGE PRO")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(.primary)
                        Text("Zero-day AI smishing heuristics & delta sync")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    RetroBadge("PRO", color: RetroTheme.textAccent, isFilled: true)
                }
                .padding(14)
            }
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
        case .sms: return .triageVolt
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
                        iconColor: .triageVolt,
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
                        iconColor: .triageVolt,
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
            color: .triageVolt,
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
                            .foregroundColor(.triageVolt)
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
                        .foregroundColor(.triageVolt)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Legitimate Message")
                            .font(.headline)
                            .foregroundColor(.triageVolt)
                        Text("Action: Allowed to Inbox (.none)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("CLEAN")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.triageVoltSubtle)
                        .foregroundColor(.triageVolt)
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
