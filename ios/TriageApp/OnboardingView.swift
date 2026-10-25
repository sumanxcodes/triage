import SwiftUI
import ComponentsKit

public struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    public var onComplete: (() -> Void)?

    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            RetroTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Logo & Brand
                        TriageLogoView(size: 60, showsGlow: true)
                            .padding(.top, 20)

                        // Hero Headline
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Private by Design")
                                .font(RetroTheme.captionLarge)
                                .foregroundColor(RetroTheme.accent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Messages.")
                                    .foregroundColor(RetroTheme.foreground)
                                Text("Your Browsing.")
                                    .foregroundColor(RetroTheme.foreground)
                                Text("Protected.")
                                    .foregroundColor(RetroTheme.accent)
                            }
                            .font(RetroTheme.urbanist(size: 32, weight: .bold))

                            Text("Dual-layer protection against scam texts and malicious links, evaluated entirely on your iPhone.")
                                .font(RetroTheme.bodyMedium)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .padding(.top, 4)
                        }

                        // Grouped Feature Highlights
                        AppCard {
                            VStack(spacing: 0) {
                                featureRow(
                                    title: "SMS Scam Filter",
                                    subtitle: "Silently routes fraudulent and unknown smishing texts to Junk.",
                                    icon: "message.badge.filled.fill",
                                    iconColor: RetroTheme.accent
                                )

                                Divider()
                                    .padding(.leading, 52)

                                featureRow(
                                    title: "Safari Fraud Shield",
                                    subtitle: "Instantly checks and blocks deceptive links while browsing in Safari.",
                                    icon: "safari.fill",
                                    iconColor: RetroTheme.accent
                                )

                                Divider()
                                    .padding(.leading, 52)

                                featureRow(
                                    title: "Zero-Data Privacy",
                                    subtitle: "No sign-in or account needed. Your private data never leaves your device.",
                                    icon: "lock.shield.fill",
                                    iconColor: RetroTheme.accent
                                )
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }

                // Sticky Bottom Action Bar
                VStack(spacing: 12) {
                    SUButton(
                        title: "Get Started",
                        color: .primary,
                        style: .filled,
                        size: .large,
                        isFullWidth: true
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let onComplete = onComplete {
                            onComplete()
                        } else {
                            dismiss()
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)

                        Text("On-Device Evaluation • Zero Telemetry")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .background(RetroTheme.background)
            }
        }
    }

    private func featureRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            AppIconWell(
                icon: icon,
                iconColor: iconColor,
                backgroundColor: RetroTheme.content1,
                size: 38,
                iconSize: 18
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(RetroTheme.headlineSmall)
                    .foregroundColor(RetroTheme.foreground)

                Text(subtitle)
                    .font(RetroTheme.captionMedium)
                    .foregroundColor(RetroTheme.secondaryForeground)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }
}
