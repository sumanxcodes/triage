import SwiftUI
import ComponentsKit

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

    var componentColor: ComponentColor {
        switch self {
        case .active: return .accent
        case .ready: return .accent
        case .setupNeeded: return .warning
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

    private var formattedThreatCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: threatCount)) ?? "\(threatCount)"
    }

    private var lastSyncDescription: String {
        if let lastSync = ThreatSyncManager.shared.lastSyncDate {
            return "Updated \(formattedRelativeDate(lastSync))"
        } else {
            return "Offline intelligence ready"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - 1. Hero Security Status
                        heroStatusSection

                        // MARK: - 2. Grouped Protection Modules
                        modulesSection

                        // MARK: - 3. Grouped Security Tools & Intelligence
                        toolsSection

                        // MARK: - 4. Pro Upgrade Banner
                        if !subscriptionManager.isProUser {
                            proBanner
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    triggerSync()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
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

    private var heroStatusSection: some View {
        AppCard {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    TriageLogoView(size: 48, showsGlow: isFullyProtected)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(isFullyProtected ? "System Protected" : "Action Needed")
                            .font(RetroTheme.headlineMedium)
                            .foregroundColor(RetroTheme.foreground)

                        Text(isFullyProtected ?
                             "SMS filter and Safari shield are actively protecting your device." :
                             "Enable shields in iPhone Settings to start protecting your device.")
                            .font(RetroTheme.bodySmall)
                            .foregroundColor(RetroTheme.secondaryForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    shieldStatusChip(
                        title: "SMS Filter",
                        isActive: isModuleProtected(smsStatus),
                        module: .sms
                    )

                    shieldStatusChip(
                        title: "Safari Shield",
                        isActive: isModuleProtected(safariStatus),
                        module: .safari
                    )
                }
            }
        }
    }

    private func shieldStatusChip(title: String, isActive: Bool, module: ModuleType) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedModule = module
        }) {
            HStack(spacing: 6) {
                Image(systemName: isActive ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isActive ? RetroTheme.accent : RetroTheme.warning)

                Text(title)
                    .font(RetroTheme.captionMedium)
                    .foregroundColor(RetroTheme.foreground)

                Spacer()

                Text(isActive ? "Active" : "Setup")
                    .font(RetroTheme.captionSmall)
                    .foregroundColor(isActive ? RetroTheme.accent : RetroTheme.warning)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? RetroTheme.accent.opacity(0.08) : RetroTheme.warning.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        (isActive ? RetroTheme.accent : RetroTheme.warning).opacity(0.18),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppSectionHeader("PROTECTION MODULES")

            AppCard {
                VStack(spacing: 0) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedModule = .sms
                    }) {
                        AppNavigationRow(
                            icon: "message.badge.filled.fill",
                            iconColor: RetroTheme.accent,
                            title: "SMS Filter",
                            subtitle: "Spam & unknown scam messages",
                            statusText: isModuleProtected(smsStatus) ? "Active" : "Action Needed",
                            badge: nil,
                            showChevron: true
                        )
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.vertical, 8)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedModule = .safari
                    }) {
                        AppNavigationRow(
                            icon: "safari.fill",
                            iconColor: RetroTheme.accent,
                            title: "Safari Shield",
                            subtitle: "Deceptive websites & fraud links",
                            statusText: isModuleProtected(safariStatus) ? "Active" : "Action Needed",
                            badge: nil,
                            showChevron: true
                        )
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppSectionHeader("SECURITY TOOLS")

            AppCard {
                VStack(spacing: 0) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showThreatSimulator = true
                    }) {
                        AppNavigationRow(
                            icon: "shield.lefthalf.filled",
                            iconColor: RetroTheme.accent,
                            title: "Test Threat Detection",
                            subtitle: "Simulate attacks to verify filtering",
                            statusText: nil,
                            badge: nil,
                            showChevron: true
                        )
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.vertical, 8)

                    HStack(spacing: 14) {
                        AppIconWell(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: RetroTheme.accent,
                            backgroundColor: RetroTheme.content1,
                            size: 44,
                            iconSize: 18
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(formattedThreatCount) Threat Signatures")
                                .font(RetroTheme.headlineSmall)
                                .foregroundColor(RetroTheme.foreground)

                            Text(lastSyncDescription)
                                .font(RetroTheme.captionMedium)
                                .foregroundColor(RetroTheme.secondaryForeground)
                        }

                        Spacer()

                        Button(action: triggerSync) {
                            HStack(spacing: 5) {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(RetroTheme.captionSmall)
                                }

                                Text(isSyncing ? "Syncing" : "Sync")
                                    .font(RetroTheme.buttonSmall)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RetroTheme.content1)
                            .foregroundColor(RetroTheme.foreground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSyncing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var proBanner: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showingPaywall = true
        }) {
            AppCard(isTappable: true) {
                AppNavigationRow(
                    icon: "sparkles",
                    iconColor: RetroTheme.accent,
                    title: "Upgrade to Triage Pro",
                    subtitle: "Zero-day AI protection & continuous updates",
                    statusText: nil,
                    badge: nil,
                    showChevron: true
                )
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

// MARK: - Retro Module Setup Sheet

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
        RetroTheme.accent
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
            return "Active heartbeat verified (\(rel))"
        case .ready:
            return "Extension active · Standing by for inspection"
        case .setupNeeded:
            return "Configuration required in iPhone Settings"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

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
            }
            .navigationTitle(moduleTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onDismiss?()
                        dismiss()
                    }) {
                        AppBadge("DONE", color: .secondary, isFilled: false)
                    }
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
        AppCard {
            HStack(spacing: 14) {
                AppIconWell(
                    icon: moduleIcon,
                    iconColor: moduleColor,
                    backgroundColor: moduleType == .sms ? RetroTheme.accentBackground : RetroTheme.content1,
                    size: 44,
                    iconSize: 18
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(moduleType == .sms ? "SMS Smishing Filter" : "Safari Web Shield")
                        .font(RetroTheme.headlineSmall)
                        .foregroundColor(RetroTheme.foreground)

                    Text(statusDescription)
                        .font(RetroTheme.captionMedium)
                        .foregroundColor(RetroTheme.secondaryForeground)
                }

                Spacer()

                AppBadge(
                    currentStatus.badgeText,
                    color: isModuleProtected(currentStatus) ? .accent : .warning,
                    isFilled: true
                )
            }
        }
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppSectionHeader("ACTIVATION INSTRUCTIONS")

            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    if moduleType == .sms {
                        retroStepRow(step: "01", text: "Open iPhone **Settings** > **Apps** > **Messages**")
                        Divider()
                        retroStepRow(step: "02", text: "Tap **Unknown & Spam**")
                        Divider()
                        retroStepRow(step: "03", text: "Toggle ON **Filter Unknown Senders**")
                        Divider()
                        retroStepRow(step: "04", text: "Select **Triage** and confirm **Enable**")
                    } else {
                        retroStepRow(step: "01", text: "Open iPhone **Settings** > **Apps** > **Safari**")
                        Divider()
                        retroStepRow(step: "02", text: "Tap **Extensions**")
                        Divider()
                        retroStepRow(step: "03", text: "Toggle ON **Triage Security**")
                        Divider()
                        retroStepRow(step: "04", text: "Set **All Websites** to **Always Allow**")
                    }
                }
            }
        }
    }

    private func retroStepRow(step: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(RetroTheme.captionSmall)
                .foregroundColor(RetroTheme.accent)

            Text(text)
                .font(RetroTheme.bodySmall)
                .foregroundColor(RetroTheme.foreground)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            SUButton(
                title: "OPEN IPHONE SETTINGS",
                color: .primary,
                style: .filled,
                size: .medium,
                isFullWidth: true
            ) {
                openSettings()
            }

            Text("Settings opens on Triage. Tap **‹ Apps** in top-left to reach \(moduleType == .sms ? "Messages" : "Safari").")
                .font(RetroTheme.captionMedium)
                .foregroundColor(RetroTheme.secondaryForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            if moduleType == .sms {
                SUButton(
                    title: "TEST WITH SMS SIMULATOR",
                    color: nil,
                    style: .light,
                    size: .medium,
                    isFullWidth: true
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showSMSSimulator = true
                }
                .padding(.top, 4)
            }

            if moduleType == .safari {
                SUButton(
                    title: "TEST SAFARI SHIELD",
                    color: nil,
                    style: .light,
                    size: .medium,
                    isFullWidth: true
                ) {
                    testInSafari()
                }
                .padding(.top, 4)

                if let msg = testPromptMessage {
                    Text(msg)
                        .font(RetroTheme.captionMedium)
                        .foregroundColor(RetroTheme.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
    }

    private func isModuleProtected(_ status: ModuleStatus) -> Bool {
        switch status {
        case .active, .ready: return true
        case .setupNeeded: return false
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

// MARK: - Retro SMS Threat Simulator Sheet

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
            color: RetroTheme.danger,
            sender: "+61 489 123 456",
            message: "AusPost: Your parcel could not be delivered due to incomplete address details. Update delivery address here: https://example.com/delivery"
        ),
        AttackPreset(
            title: "CommBank",
            icon: "building.columns.fill",
            color: RetroTheme.warning,
            sender: "+61 412 987 654",
            message: "CommBank: Unusual sign-in attempt detected from an unrecognized device. Verify NetBank identity: https://example.com/auth"
        ),
        AttackPreset(
            title: "Linkt Toll",
            icon: "car.fill",
            color: RetroTheme.accent,
            sender: "+61 400 555 123",
            message: "Linkt: You have an unpaid toll invoice of $12.40. Avoid late fees by paying now: https://example.com/toll"
        ),
        AttackPreset(
            title: "Clean SMS",
            icon: "bubble.left.and.bubble.right.fill",
            color: RetroTheme.success,
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
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header Description
                        AppCard {
                            HStack(spacing: 12) {
                                AppIconWell(
                                    icon: "shield.lefthalf.filled",
                                    iconColor: RetroTheme.accent,
                                    backgroundColor: RetroTheme.content1,
                                    size: 40,
                                    iconSize: 18
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Threat Inspection Simulator")
                                        .font(RetroTheme.bodyMedium)
                                        .foregroundColor(RetroTheme.foreground)
                                    Text("Evaluates message candidates against the on-device SQLite database.")
                                        .font(RetroTheme.captionMedium)
                                        .foregroundColor(RetroTheme.secondaryForeground)
                                }
                            }
                        }

                        // Attack Presets
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("SAMPLE ATTACK SCENARIOS")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                                        let isSelected = selectedPresetIndex == index
                                        Button(action: {
                                             selectPreset(index)
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: preset.icon)
                                                    .font(RetroTheme.captionSmall)
                                                    .foregroundColor(isSelected ? RetroTheme.accentContrast : preset.color)
                                                Text(preset.title)
                                                    .font(RetroTheme.captionLarge)
                                                    .foregroundColor(isSelected ? RetroTheme.accentContrast : RetroTheme.foreground)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? RetroTheme.accent : RetroTheme.content1)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Simulated Message Editor
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("INCOMING PAYLOAD BUFFER")

                            AppCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Text("SENDER:")
                                            .font(RetroTheme.captionSmall)
                                            .foregroundColor(RetroTheme.secondaryForeground)
                                        TextField("Sender Number", text: $senderNumber)
                                            .font(RetroTheme.bodySmall)
                                            .foregroundColor(RetroTheme.foreground)
                                            .keyboardType(.phonePad)
                                    }

                                    Divider()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("MESSAGE TEXT:")
                                            .font(RetroTheme.captionSmall)
                                            .foregroundColor(RetroTheme.secondaryForeground)
                                        TextEditor(text: $messageBody)
                                            .font(RetroTheme.bodySmall)
                                            .foregroundColor(RetroTheme.foreground)
                                            .frame(minHeight: 64)
                                            .scrollContentBackground(.hidden)
                                    }
                                }
                            }
                        }

                        // Run Inspection Button
                        SUButton(
                            title: "EXECUTE THREAT INSPECTION",
                            color: .primary,
                            style: .filled,
                            size: .medium,
                            isFullWidth: true
                        ) {
                            runEvaluation()
                        }

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
            }
            .navigationTitle("Threat Simulator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        AppBadge("DONE", color: .primary, isFilled: false)
                    }
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
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                switch verdict {
                case .threat(let url, let brand, let category):
                    HStack(spacing: 10) {
                        Image(systemName: "shield.slash.fill")
                            .font(RetroTheme.headlineSmall)
                            .foregroundColor(RetroTheme.danger)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Malicious Smishing Detected")
                                .font(RetroTheme.headlineSmall)
                                .foregroundColor(RetroTheme.danger)
                            Text("Action: Filtered to Junk (.junk)")
                                .font(RetroTheme.captionMedium)
                                .foregroundColor(RetroTheme.secondaryForeground)
                        }

                        Spacer()

                        AppBadge("JUNKED", color: .danger, isFilled: true)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        if let b = brand {
                            AppDetailRow(label: "IMPERSONATING", value: b)
                        }
                        AppDetailRow(label: "CATEGORY", value: category.capitalized)
                        AppDetailRow(label: "EXTRACTED URL", value: url)
                        AppDetailRow(label: "ROUTING", value: "Messages > Junk folder")
                        AppDetailRow(label: "AUDIT LOG", value: "Recorded to local SQLite DB")
                    }

                case .clean:
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(RetroTheme.headlineSmall)
                            .foregroundColor(RetroTheme.success)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clean Message Verified")
                                .font(RetroTheme.headlineSmall)
                                .foregroundColor(RetroTheme.success)
                            Text("Action: Allowed to Inbox (.none)")
                                .font(RetroTheme.captionMedium)
                                .foregroundColor(RetroTheme.secondaryForeground)
                        }

                        Spacer()

                        AppBadge("CLEAN", color: .success, isFilled: true)
                    }

                    Divider()

                    Text("No deceptive URLs, homoglyphs, or known threat hashes were detected. Message allowed to primary inbox.")
                        .font(RetroTheme.captionMedium)
                        .foregroundColor(RetroTheme.secondaryForeground)

                case .unverified(let url):
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.shield.fill")
                            .font(RetroTheme.headlineSmall)
                            .foregroundColor(RetroTheme.warning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unverified Link Detected")
                                .font(RetroTheme.headlineSmall)
                                .foregroundColor(RetroTheme.warning)
                            Text("Action: Defer to cloud check (.allow)")
                                .font(RetroTheme.captionMedium)
                                .foregroundColor(RetroTheme.secondaryForeground)
                        }

                        Spacer()

                        AppBadge("DEFERRED", color: .warning, isFilled: true)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        AppDetailRow(label: "EXTRACTED URL", value: url)
                        AppDetailRow(label: "CACHE STATUS", value: "Hash absent from offline DB")
                        AppDetailRow(label: "NEXT ACTION", value: "Query cloud threat lookup service")
                    }
                }
            }
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
