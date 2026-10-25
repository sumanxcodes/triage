import SwiftUI

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
                            RetroBadge("PRIVATE BY DESIGN // SYSTEM INIT", color: RetroTheme.textAccent, isFilled: true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR MESSAGES.")
                                    .foregroundColor(.primary)
                                Text("YOUR BROWSING.")
                                    .foregroundColor(.primary)
                                Text("PROTECTED.")
                                    .foregroundColor(RetroTheme.textAccent)
                            }
                            .font(.system(size: 30, weight: .heavy, design: .monospaced))

                            Text("Dual-layer cyber defense against smishing scams and fraudulent links, evaluated 100% on your iPhone.")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }

                        // Feature Cards
                        VStack(spacing: 12) {
                            featureCard(
                                stepNumber: "[01]",
                                title: "SMS SMISHING FILTER",
                                subtitle: "Silently intercepts unknown scam texts and routes them to Junk before they ring.",
                                icon: "message.badge.filled.fill",
                                iconColor: RetroTheme.textAccent
                            )

                            featureCard(
                                stepNumber: "[02]",
                                title: "SAFARI WEB SHIELD",
                                subtitle: "Cross-checks dangerous links in WebKit against local threat hashes in <1ms.",
                                icon: "safari.fill",
                                iconColor: .blue
                            )

                            featureCard(
                                stepNumber: "[03]",
                                title: "ZERO TELEMETRY",
                                subtitle: "No account required. No analytics. Your private data never leaves your device.",
                                icon: "lock.shield.fill",
                                iconColor: RetroTheme.textAccent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }

                // Sticky Bottom Action Bar
                VStack(spacing: 10) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let onComplete = onComplete {
                            onComplete()
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("INITIALIZE PROTECTION")
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RetroButtonStyle(
                        backgroundColor: RetroTheme.volt,
                        foregroundColor: .black,
                        cornerRadius: 8
                    ))

                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)

                        Text("LOCAL SQLITE // AIR-GAPPED EVALUATION")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
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
        RetroCard(cornerRadius: 8) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Rectangle()
                        .fill(RetroTheme.elevatedSurface)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Rectangle()
                                .stroke(RetroTheme.border, lineWidth: 1.5)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(stepNumber)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(RetroTheme.textAccent)

                        Text(title)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.primary)
                    }

                    Text(subtitle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineSpacing(1.5)
                }

                Spacer()
            }
            .padding(12)
        }
    }
}
