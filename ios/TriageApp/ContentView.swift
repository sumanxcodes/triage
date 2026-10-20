import SwiftUI

struct ContentView: View {
    @State private var showingOnboarding = false
    @State private var threatCount = ThreatDatabase.shared.count()
    @State private var isSyncing = false
    @State private var syncStatusMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top, 32)

                Text("Triage Active")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Dual-layer protection is running: SMS Filter & Safari Web Extension.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

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
                .padding(.horizontal, 24)

                Spacer()

                Button(action: {
                    showingOnboarding = true
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("View Extension Setup Guide")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Triage Security")
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
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
