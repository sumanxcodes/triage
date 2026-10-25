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
                    VStack(alignment: .leading, spacing: 20) {
                        // Top Badge
                        TriageLogoView(size: 64, showsGlow: true)
                            .padding(.top, 16)

                        // Eyebrow & Hero Headline
                        VStack(alignment: .leading, spacing: 8) {
                            AppBadge("PRIVATE BY DESIGN // SYSTEM INIT", color: .accent, isFilled: true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Messages.")
                                    .foregroundColor(RetroTheme.foreground)
                                Text("Your Browsing.")
                                    .foregroundColor(RetroTheme.foreground)
                                Text("Protected.")
                                    .foregroundColor(RetroTheme.accent)
                            }
                            .font(RetroTheme.urbanist(size: 30, weight: .bold))

                            Text("Dual-layer cyber defense against smishing scams and fraudulent links, evaluated 100% on your iPhone.")
                                .font(RetroTheme.bodySmall)
                                .foregroundColor(RetroTheme.secondaryForeground)
                                .padding(.top, 2)
                        }

                        // Feature Cards
                        VStack(spacing: 12) {
                            featureCard(
                                stepNumber: "[01]",
                                title: "SMS SMISHING FILTER",
                                subtitle: "Silently intercepts unknown scam texts and routes them to Junk before they ring.",
                                icon: "message.badge.filled.fill",
                                iconColor: RetroTheme.accent
                            )

                            featureCard(
                                stepNumber: "[02]",
                                title: "SAFARI WEB SHIELD",
                                subtitle: "Cross-checks dangerous links in WebKit against local threat hashes in <1ms.",
                                icon: "safari.fill",
                                iconColor: RetroTheme.accent
                            )

                            featureCard(
                                stepNumber: "[03]",
                                title: "ZERO TELEMETRY",
                                subtitle: "No account required. No analytics. Your private data never leaves your device.",
                                icon: "lock.shield.fill",
                                iconColor: RetroTheme.accent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }

                // Sticky Bottom Action Bar
                VStack(spacing: 10) {
                    SUButton(
                        title: "INITIALIZE PROTECTION",
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
                        Image(systemName: "shield.lefthalf.filled")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)

                        Text("LOCAL SQLITE // AIR-GAPPED EVALUATION")
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.secondaryForeground)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(RetroTheme.background)
            }
        }
    }

    private func featureCard(
        stepNumber: String,
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        AppCard {
            HStack(alignment: .top, spacing: 12) {
                AppIconWell(
                    icon: icon,
                    iconColor: iconColor,
                    backgroundColor: RetroTheme.content1,
                    size: 38,
                    iconSize: 16
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(stepNumber)
                            .font(RetroTheme.captionSmall)
                            .foregroundColor(RetroTheme.accent)

                        Text(title)
                            .font(RetroTheme.bodyMedium)
                            .foregroundColor(RetroTheme.foreground)
                    }

                    Text(subtitle)
                        .font(RetroTheme.captionMedium)
                        .foregroundColor(RetroTheme.secondaryForeground)
                        .lineSpacing(1.5)
                }

                Spacer()
            }
            .padding(12)
        }
    }
}
