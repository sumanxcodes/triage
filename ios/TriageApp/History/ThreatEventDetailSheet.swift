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
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(RetroTheme.dangerBackground)
                                    .frame(width: 58, height: 58)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(RetroTheme.border, lineWidth: 1)
                                    )

                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(RetroTheme.headlineLarge)
                                    .foregroundColor(RetroTheme.danger)
                            }
                            .padding(.top, 8)

                            Text(event.targetBrand ?? (event.source == "sms" ? "SMS Threat" : "Safari Threat"))
                                .font(RetroTheme.headlineMedium)
                                .foregroundColor(RetroTheme.foreground)

                            HStack(spacing: 6) {
                                RetroBadge(event.source == "sms" ? "SMS PHISHING" : "WEB PHISHING", color: .danger, isFilled: true)
                                RetroBadge(event.actionTaken == "blocked" ? "BLOCKED" : "JUNKED", color: .danger, isFilled: false)
                            }
                        }

                        // Threat Target Details Card
                        RetroCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("THREAT TELEMETRY")
                                    .font(RetroTheme.captionSmall)
                                    .foregroundColor(RetroTheme.secondaryForeground)

                                if let sender = event.sender, !sender.isEmpty {
                                    detailRow(label: "SENDER", value: sender)
                                    Divider()
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("TARGET PAYLOAD")
                                        .font(RetroTheme.captionSmall)
                                        .foregroundColor(RetroTheme.secondaryForeground)

                                    Text(event.target)
                                        .font(RetroTheme.captionMedium)
                                        .foregroundColor(RetroTheme.foreground)
                                        .lineLimit(4)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(RetroTheme.content1)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
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

                                detailRow(label: "CATEGORY", value: event.category.capitalized)
                                SUDivider()
                                detailRow(label: "TIMESTAMP", value: event.timestamp.formatted(date: .numeric, time: .standard))
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 16)

                        // On-Device Guarantee Card
                        RetroCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(RetroTheme.success)
                                    .font(RetroTheme.headlineSmall)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("LOCAL AUDIT VERIFIED")
                                        .font(RetroTheme.bodyMedium)
                                        .foregroundColor(RetroTheme.foreground)

                                    Text("Evaluated locally using SQLite O(1) hash table. Message content, sender ID, and private browsing data never left this device.")
                                        .font(RetroTheme.captionMedium)
                                        .foregroundColor(RetroTheme.secondaryForeground)
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
                .font(RetroTheme.captionSmall)
                .foregroundColor(RetroTheme.secondaryForeground)
            Spacer()
            Text(value)
                .font(RetroTheme.bodySmall)
                .foregroundColor(RetroTheme.foreground)
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
