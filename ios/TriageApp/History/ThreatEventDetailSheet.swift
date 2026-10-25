import SwiftUI
import ComponentsKit

public struct ThreatEventDetailSheet: View {
    let event: ThreatEventRecord
    @Environment(\.dismiss) private var dismiss
    @State private var copiedURL: Bool = false

    public init(event: ThreatEventRecord) {
        self.event = event
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // Header Status
                        VStack(spacing: 10) {
                            ZStack {
                                Rectangle()
                                    .fill(RetroTheme.elevatedSurface)
                                    .frame(width: 58, height: 58)
                                    .overlay(
                                        Rectangle()
                                            .stroke(RetroTheme.border, lineWidth: 2)
                                    )

                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 8)

                            Text(event.targetBrand ?? (event.source == "sms" ? "SMS THREAT" : "SAFARI THREAT"))
                                .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                .foregroundColor(.primary)

                            HStack(spacing: 6) {
                                RetroBadge(event.source == "sms" ? "SMS PHISHING" : "WEB PHISHING", color: .red, isFilled: true)
                                RetroBadge(event.actionTaken == "blocked" ? "BLOCKED" : "JUNKED", color: .red, isFilled: false)
                            }
                        }

                        // Threat Target Details Card
                        RetroCard(cornerRadius: 10) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("// THREAT TELEMETRY")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.secondary)

                                if let sender = event.sender, !sender.isEmpty {
                                    detailRow(label: "SENDER", value: sender)
                                    Divider()
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("TARGET PAYLOAD")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.secondary)

                                    Text(event.target)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .lineLimit(4)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(RetroTheme.elevatedSurface)
                                        .overlay(
                                            Rectangle()
                                                .stroke(RetroTheme.border, lineWidth: 1)
                                        )
                                }

                                SUButton(
                                    title: copiedURL ? "COPIED TO CLIPBOARD" : "COPY THREAT URL",
                                    color: copiedURL ? .primary : nil,
                                    style: copiedURL ? .filled : .light,
                                    size: .small,
                                    isFullWidth: true
                                ) {
                                    copyToClipboard()
                                }

                                SUDivider()

                                detailRow(label: "CATEGORY", value: event.category.uppercased())
                                SUDivider()
                                detailRow(label: "TIMESTAMP", value: event.timestamp.formatted(date: .numeric, time: .standard))
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 16)

                        // On-Device Guarantee Card
                        RetroCard(cornerRadius: 10) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(RetroTheme.textAccent)
                                    .font(.system(size: 18, weight: .bold))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("LOCAL AUDIT VERIFIED")
                                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                        .foregroundColor(.primary)

                                    Text("Evaluated locally using SQLite O(1) hash table. Message content, sender ID, and private browsing data never left this device.")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(14)
                        }
                        .padding(.horizontal, 16)

                        // Delete Event Action
                        SUButton(
                            title: "DELETE LOG ENTRY",
                            color: .danger,
                            style: .light,
                            size: .medium,
                            isFullWidth: true
                        ) {
                            deleteAndDismiss()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("LOG DETAIL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        RetroBadge("CLOSE", color: .secondary, isFilled: false)
                    }
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
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
