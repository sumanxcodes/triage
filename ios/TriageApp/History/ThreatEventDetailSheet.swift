import SwiftUI

public struct ThreatEventDetailSheet: View {
    let event: ThreatEventRecord
    @Environment(\.dismiss) private var dismiss
    @State private var copiedURL: Bool = false

    public init(event: ThreatEventRecord) {
        self.event = event
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon & Status
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 80, height: 80)

                            Image(systemName: "exclamationmark.shield.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 16)

                        Text(event.targetBrand ?? (event.source == "sms" ? "SMS Threat" : "Safari Threat"))
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 6) {
                            Text(event.source == "sms" ? "SMS Phishing" : "Web Phishing")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(6)

                            Text(event.actionTaken == "blocked" ? "Blocked at Navigation" : "Filtered to Junk")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Threat Target Details Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Threat Information")
                            .font(.headline)

                        if let sender = event.sender, !sender.isEmpty {
                            detailRow(label: "Sender", value: sender)
                            Divider()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Blocked URL / Target")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(event.target)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .lineLimit(3)

                                Spacer()

                                Button(action: copyToClipboard) {
                                    Image(systemName: copiedURL ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(copiedURL ? .green : .blue)
                                        .font(.subheadline)
                                }
                            }
                            .padding(10)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                        }

                        Divider()

                        detailRow(label: "Threat Classification", value: event.category.capitalized)
                        Divider()
                        detailRow(label: "Intercepted On", value: event.timestamp.formatted(date: .long, time: .shortened))
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    // On-Device Guarantee Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.indigo)
                            Text("100% On-Device Audit Log")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }

                        Text("This event was evaluated and logged locally using Triage's on-device SQLite threat database. No SMS text, sender, or browsing history has ever been transmitted off your iPhone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    // Delete Event Action
                    Button(role: .destructive, action: deleteAndDismiss) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Log Entry")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = event.target
        copiedURL = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedURL = false
        }
    }

    private func deleteAndDismiss() {
        ThreatDatabase.shared.deleteEvent(id: event.id)
        dismiss()
    }
}
