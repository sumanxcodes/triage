import SwiftUI

struct ContentView: View {
    @State private var showingOnboarding = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                Text("Triage Active")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Dual-layer protection is running: SMS Filter & Safari Web Extension.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: {
                    showingOnboarding = true
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("View Extension Setup Guide")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Triage Security")
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
        }
    }
}
