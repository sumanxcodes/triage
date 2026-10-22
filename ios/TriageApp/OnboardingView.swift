import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Hero Crest
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 88, height: 88)

                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Welcome to Triage")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))

                    Text("Dual-layer privacy protection against smishing and link phishing for iPhone.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Feature Highlights
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(
                        icon: "message.badge.filled.fill",
                        color: .green,
                        title: "SMS Threat Filter",
                        description: "Identifies and filters deceptive smishing texts from unknown senders on-device."
                    )

                    featureRow(
                        icon: "safari.fill",
                        color: .blue,
                        title: "Safari Web Shield",
                        description: "Intercepts malicious web links in real time before fake login pages or malware load."
                    )

                    featureRow(
                        icon: "hand.raised.fill",
                        color: .indigo,
                        title: "Zero-Telemetry Privacy",
                        description: "100% on-device hash evaluation. No accounts, no data collection, no browsing logs."
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Primary CTA Button
                VStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Configure your extensions on the Protection dashboard.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
