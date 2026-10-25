import SwiftUI

public struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    public var onComplete: (() -> Void)?

    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Top Logo Badge
                        TriageLogoView(size: 64, showsGlow: true)
                            .padding(.top, 16)

                        // Eyebrow & Hero Headline
                        VStack(alignment: .leading, spacing: 6) {
                            Text("// PRIVATE BY DESIGN")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.triageVolt)
                                .tracking(1.0)

                            VStack(alignment: .leading, spacing: 0) {
                                Text("Your messages.")
                                    .foregroundColor(.primary)
                                Text("Your browsing.")
                                    .foregroundColor(.primary)
                                Text("Protected.")
                                    .foregroundColor(.triageVolt)
                            }
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .lineSpacing(-2)

                            Text("Dual-layer protection from scam texts and malicious links, entirely on your iPhone.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Feature Rows
                        VStack(spacing: 16) {
                            onboardingRow(
                                stepNumber: "01",
                                title: "SMS Smishing Filter",
                                subtitle: "Silently moves scam texts to Junk.",
                                icon: "message.badge.filled.fill",
                                iconColor: .triageVolt
                            )

                            Divider()
                                .padding(.leading, 32)

                            onboardingRow(
                                stepNumber: "02",
                                title: "Safari Web Shield",
                                subtitle: "Checks dangerous links before they load.",
                                icon: "safari.fill",
                                iconColor: .blue
                            )

                            Divider()
                                .padding(.leading, 32)

                            onboardingRow(
                                stepNumber: "03",
                                title: "Zero Telemetry",
                                subtitle: "Nothing personal ever leaves your device.",
                                icon: "lock.shield.fill",
                                iconColor: .purple
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                // Sticky Bottom Action Bar
                VStack(spacing: 12) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let onComplete = onComplete {
                            onComplete()
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("SET UP PROTECTION")
                                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                                .tracking(0.5)

                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.heavy))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.triageVoltRaw)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)

                        Text("On-device processing • No account required")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(
                    Color(.systemBackground)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: -3)
                )
            }
        }
    }

    private func onboardingRow(
        stepNumber: String,
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(stepNumber)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.bold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 38, height: 38)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.triageCardBorder, lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
        }
    }
}
