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
                    // Header Status
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(subscriptionManager.isProUser ?
                                      LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                      LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)

                            Image(systemName: subscriptionManager.isProUser ? "shield.checkered" : "shield.lefthalf.filled.badge.checkmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 16)

                        HStack(spacing: 8) {
                            Text("Triage Active")
                                .font(.title2)
                                .fontWeight(.bold)

                            if subscriptionManager.isProUser {
                                Text("PRO")
                                    .font(.system(size: 11, weight: .heavy))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }

                        Text("Dual-layer protection: SMS Filter & Safari Web Extension.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Pro Upgrade Banner (if free tier)
                    if !subscriptionManager.isProUser {
                        Button(action: { showingPaywall = true }) {
                            HStack(spacing: 14) {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(.yellow)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Triage Pro")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Unlock Gemini Zero-Day AI & hourly updates")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.85))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.indigo, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .indigo.opacity(0.3), radius: 6, y: 3)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Pro Active Status Card
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Triage Pro Active")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Real-time Gemini AI & continuous threat updates active.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }

                    // Threat Status Card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Offline Threat Database")
                                    .font(.headline)
                                Text("\(threatCount) known threat hashes active")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "internaldrive.fill")
                                .font(.title2)
                                .foregroundColor(.indigo)
                        }

                        Divider()

                        HStack {
                            if let lastSync = ThreatSyncManager.shared.lastSyncDate {
                                Text("Last synced: \(lastSync, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Last synced: Never")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: triggerSync) {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sync Now")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .disabled(isSyncing)
                        }

                        if let msg = syncStatusMessage {
                            Text(msg)
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingOnboarding = true
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("View Extension Setup Guide")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }

                        if !subscriptionManager.isProUser {
                            Button(action: {
                                showingPaywall = true
                            }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                    Text("View Pro Plans")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Triage Security")
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

    private func triggerSync() {
        isSyncing = true
        syncStatusMessage = "Syncing threat hashes..."
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
