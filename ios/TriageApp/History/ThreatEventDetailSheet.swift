import SwiftUI
import ComponentsKit

public struct ThreatEventDetailSheet: View {
    let event: ThreatEventRecord
    @Environment(\.dismiss) private var dismiss
    @State private var copiedURL: Bool = false

    public init(event: ThreatEventRecord) {
        self.event = event
    }

    private var headerTitle: String {
        if let brand = event.targetBrand, !brand.isEmpty {
            return brand
        } else if let host = URL(string: event.target)?.host, !host.isEmpty {
            return host
        } else {
            return event.source == "sms" ? "Scam Message" : "Deceptive Link"
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero Header
                        VStack(spacing: 10) {
                            AppIconWell(
                                icon: "exclamationmark.shield.fill",
                                iconColor: RetroTheme.danger,
                                backgroundColor: RetroTheme.dangerBackground,
                                size: 56,
                                iconSize: 24
                            )
                            .padding(.top, 8)

                            Text(headerTitle)
                                .font(RetroTheme.headlineMedium)
                                .foregroundColor(RetroTheme.foreground)
                                .multilineTextAlignment(.center)

                            Text(event.actionTaken == "blocked" ? "Blocked in Safari" : "Filtered to Junk Messages")
                                .font(RetroTheme.captionLarge)
                                .foregroundColor(RetroTheme.secondaryForeground)
                        }
                        .padding(.top, 8)

                        // Section 1: Incident Details
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("INCIDENT DETAILS")

                            AppCard {
                                VStack(spacing: 12) {
                                    AppDetailRow(label: "Source", value: event.source == "sms" ? "SMS Filter" : "Safari Shield")
                                    Divider()
                                    if let sender = event.sender, !sender.isEmpty {
                                        AppDetailRow(label: "Sender", value: sender)
                                        Divider()
                                    }
                                    AppDetailRow(label: "Category", value: event.category.capitalized)
                                    Divider()
                                    AppDetailRow(label: "Action", value: event.actionTaken == "blocked" ? "Blocked" : "Filtered to Junk")
                                    Divider()
                                    AppDetailRow(label: "Detected", value: event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Section 2: Suspicious Target
                        VStack(alignment: .leading, spacing: 8) {
                            AppSectionHeader("SUSPICIOUS TARGET")

                            AppCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(event.target)
                                        .font(RetroTheme.captionMedium)
                                        .foregroundColor(RetroTheme.foreground)
                                        .lineLimit(4)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(RetroTheme.content1)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                    SUButton(
                                        title: copiedURL ? "Copied to Clipboard" : "Copy Target URL",
                                        color: copiedURL ? .primary : nil,
                                        style: copiedURL ? .filled : .light,
                                        size: .small,
                                        isFullWidth: true
                                    ) {
                                        copyToClipboard()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Section 3: Privacy Guarantee
                        AppCard {
                            HStack(alignment: .top, spacing: 12) {
                                AppIconWell(
                                    icon: "lock.shield.fill",
                                    iconColor: RetroTheme.accent,
                                    backgroundColor: RetroTheme.content1,
                                    size: 38,
                                    iconSize: 17
                                )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Evaluated On-Device")
                                        .font(RetroTheme.bodyMedium)
                                        .foregroundColor(RetroTheme.foreground)

                                    Text("This threat was analyzed locally on your iPhone. Your messages and browsing activity were never shared or uploaded.")
                                        .font(RetroTheme.captionMedium)
                                        .foregroundColor(RetroTheme.secondaryForeground)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Section 4: Delete Record Action
                        Button(role: .destructive, action: deleteAndDismiss) {
                            Text("Delete Threat Record")
                                .font(RetroTheme.buttonMedium)
                                .foregroundColor(RetroTheme.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RetroTheme.dangerBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Threat Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(RetroTheme.buttonSmall)
                    .foregroundColor(RetroTheme.accent)
                }
            }
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
