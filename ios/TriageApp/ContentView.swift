import SwiftUI

struct ContentView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingOnboarding = false
    @State private var showingPaywall = false
    @State private var threatCount = ThreatDatabase.shared.count()
    @State private var isSyncing = false
    @State private var syncStatusMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Hero Protection Status
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(subscriptionManager.isProUser ?
                                      LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                      LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 84, height: 84)
                                .shadow(color: (subscriptionManager.isProUser ? Color.purple : Color.blue).opacity(0.3), radius: 10, y: 5)

                            Image(systemName: subscriptionManager.isProUser ? "shield.checkered" : "shield.lefthalf.filled.badge.checkmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)

                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Protection Active")
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

                            Text("Dual-layer on-device SMS & Safari protection.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 4)

                    // MARK: - Active Modules Section
                    VStack(spacing: 0) {
                        moduleRow(
                            icon: "message.badge.filled.fill",
                            iconColor: .green,
                            title: "SMS Smishing Filter",
                            subtitle: "On-device SQLite URL analysis",
                            status: "Active"
                        )

                        Divider()
                            .padding(.leading, 56)

                        moduleRow(
                            icon: "safari.fill",
                            iconColor: .blue,
                            title: "Safari Extension",
                            subtitle: "Real-time phishing link blocker",
                            status: "Active"
                        )
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
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
                                HStack(spacing: 6) {
                                    if isSyncing {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Sync Now")
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isSyncing)
                        }

                        if let msg = syncStatusMessage {
                            HStack {
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
                    .cornerRadius(14)
                    .padding(.horizontal, 16)

                    // MARK: - Triage Pro Banner (if Free) or Pro Active Card (if Pro)
                    if !subscriptionManager.isProUser {
                        Button(action: { showingPaywall = true }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 42, height: 42)
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
                            .cornerRadius(14)
                            .shadow(color: .indigo.opacity(0.25), radius: 6, y: 3)
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
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }

                    // MARK: - Setup Guide Link
                    Button(action: { showingOnboarding = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                            Text("Extension Setup & Help Guide")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Triage Security")
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
            .onAppear {
                threatCount = ThreatDatabase.shared.count()
            }
        }
    }

    // MARK: - Subviews

    private func moduleRow(icon: String, iconColor: Color, title: String, subtitle: String, status: String) -> some View {
        Button(action: { showingOnboarding = true }) {
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

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(status)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(14)
        }
        .buttonStyle(.plain)
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
                }
            } catch {
                await MainActor.run {
                    syncStatusMessage = "Sync failed: \(error.localizedDescription)"
                    isSyncing = false
                }
            }
        }
    }
}
