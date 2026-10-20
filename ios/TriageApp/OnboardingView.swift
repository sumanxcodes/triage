import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enable Protection")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Follow these two steps to activate Triage on your device.")
                            .foregroundColor(.secondary)
                    }

                    // Step 1: SMS Filter Extension
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "message.badge.filled.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("Step 1: Enable SMS Filtering")
                                .font(.headline)
                        }

                        Text("1. Open **Settings** on your iPhone.\n2. Tap **Messages**.\n3. Scroll down to **Unknown & Spam**.\n4. Under SMS Filtering, select **Triage**.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Step 2: Safari Web Extension
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "safari.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Step 2: Enable Safari Extension")
                                .font(.headline)
                        }

                        Text("1. Open **Settings** on your iPhone.\n2. Tap **Safari** -> **Extensions**.\n3. Toggle on **Triage Security**.\n4. Set permissions to **Always Allow**.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
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
}
