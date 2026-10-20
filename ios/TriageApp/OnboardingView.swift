import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enable Protection")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Follow these two steps to activate Triage on your iPhone.")
                            .foregroundColor(.secondary)
                    }

                    // Step 1: SMS Filter Extension
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "message.badge.filled.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("Step 1: Enable SMS Filtering")
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            guideStep(
                                number: "1",
                                text: "Open **Settings** (on iOS 18, tap **Apps** then **Messages**; or search for **Messages**)."
                            )
                            guideStep(
                                number: "2",
                                text: "Scroll down to the **Message Filtering** section."
                            )
                            guideStep(
                                number: "3",
                                text: "Turn **ON** the **Filter Unknown Senders** toggle."
                            )
                            guideStep(
                                number: "4",
                                text: "Tap **Unknown & Spam** (or **SMS Filtering**) right below it."
                            )
                            guideStep(
                                number: "5",
                                text: "Under SMS Filtering, select **Triage** and tap **Enable**."
                            )
                        }

                        // Physical device notice
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            Text("**Note for Simulator:** Apple disables the cellular SMS filtering menu on iOS Simulators without cellular hardware. Test on a physical iPhone to activate.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)

                    // Step 2: Safari Web Extension
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "safari.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Step 2: Enable Safari Extension")
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            guideStep(
                                number: "1",
                                text: "Open **Settings** -> **Safari** (or **Apps -> Safari**)."
                            )
                            guideStep(
                                number: "2",
                                text: "Tap **Extensions**."
                            )
                            guideStep(
                                number: "3",
                                text: "Toggle **ON** **Triage Security**."
                            )
                            guideStep(
                                number: "4",
                                text: "Under Permissions, select **All Websites** -> **Always Allow**."
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)

                    // Settings shortcut button
                    Button(action: openSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open iOS Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func guideStep(number: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
