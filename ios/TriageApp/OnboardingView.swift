import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var refreshId = UUID()

    private var smsStatus: ModuleStatus {
        if let date = AppGroup.lastSMSEvaluationDate {
            return .active(date)
        } else if AppGroup.isSMSConfiguredByUser {
            return .ready
        } else {
            return .setupNeeded
        }
    }

    private var safariStatus: ModuleStatus {
        if let date = AppGroup.lastSafariEvaluationDate {
            return .active(date)
        } else if AppGroup.isSafariConfiguredByUser {
            return .ready
        } else {
            return .setupNeeded
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Enable Protection")
                            .font(.system(.title, design: .rounded, weight: .bold))

                        Text("Complete these two steps in iOS Settings to activate real-time threat interception.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)

                    // Step 1: SMS Filter Extension Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "message.badge.filled.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.green)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("1. SMS Threat Filter")
                                    .font(.headline)
                                Text("Filter smishing and spam messages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            statusBadge(smsStatus)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            stepRow(number: "1", text: "Open **Settings** > **Apps** > **Messages**")
                            stepRow(number: "2", text: "Tap **Unknown & Spam**")
                            stepRow(number: "3", text: "Turn ON **Filter Unknown Senders**")
                            stepRow(number: "4", text: "Under SMS Filtering, select **Triage** and tap **Enable**")
                        }

                        // Simulator caveat banner
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.footnote)
                                .padding(.top, 1)

                            Text("**Simulator Note:** Cellular SMS filtering is disabled on iOS Simulators without cellular hardware. Test on a physical iPhone to activate.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Step 2: Safari Web Extension Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "safari.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("2. Safari Web Shield")
                                    .font(.headline)
                                Text("Block deceptive links in real time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            statusBadge(safariStatus)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            stepRow(number: "1", text: "Open **Settings** > **Safari** (or **Apps** > **Safari**)")
                            stepRow(number: "2", text: "Tap **Extensions**")
                            stepRow(number: "3", text: "Turn ON **Triage Security**")
                            stepRow(number: "4", text: "Under Permissions, select **All Websites** > **Always Allow**")
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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
                            .frame(minHeight: 24)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Button(action: testSafari) {
                            HStack(spacing: 8) {
                                Image(systemName: "safari")
                                    .font(.body.weight(.semibold))
                                Text("Test Safari Extension")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 24)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        AppGroup.isSMSConfiguredByUser = true
                        AppGroup.isSafariConfiguredByUser = true
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    refreshId = UUID()
                }
            }
        }
        .id(refreshId)
    }

    private func statusBadge(_ status: ModuleStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.badgeColor)
                .frame(width: 7, height: 7)
            Text(status.badgeText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(status.badgeColor)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(status.badgeColor.opacity(0.12))
        .cornerRadius(6)
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
}
