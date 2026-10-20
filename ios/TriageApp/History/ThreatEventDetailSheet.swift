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
                VStack(spacing: 20) {
                    // Header Icon & Status
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 76, height: 76)

                            Image(systemName: "exclamationmark.shield.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 12)

                        Text(event.targetBrand ?? (event.source == "sms" ? "SMS Threat" : "Safari Threat"))
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 6) {
                            Text(event.source == "sms" ? "SMS Phishing" : "Web Phishing")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .clipShape(Capsule())

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
                            Text("Blocked Link")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(event.target)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(4)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(10)
                        }

                        // Full 44pt Touch Target Action Button (Apple HIG Mandate)
                        Button(action: copyToClipboard) {
                            HStack(spacing: 6) {
                                Image(systemName: copiedURL ? "checkmark" : "doc.on.doc")
                                Text(copiedURL ? "Copied to Clipboard" : "Copy Threat URL")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(copiedURL ? Color.green.opacity(0.12) : Color.blue.opacity(0.1))
                            .foregroundColor(copiedURL ? .green : .blue)
                            .cornerRadius(10)
                        }

                        Divider()

                        detailRow(label: "Threat Classification", value: event.category.capitalized)
                        Divider()
                        detailRow(label: "Intercepted On", value: event.timestamp.formatted(date: .long, time: .shortened))
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    // On-Device Guarantee Card
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.indigo)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("On-Device Evaluation")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Evaluated and logged locally using Triage's on-device SQLite database. No SMS text, sender, or browsing history has ever left your iPhone.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    // Delete Event Action
                    Button(role: .destructive, action: deleteAndDismiss) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Log Entry")
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedURL = false
        }
    }

    private func deleteAndDismiss() {
        ThreatDatabase.shared.deleteEvent(id: event.id)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}
