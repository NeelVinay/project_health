import SwiftUI

struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep = 0

    private let totalSteps = 3

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: step == currentStep ? 10 : 8, height: step == currentStep ? 10 : 8)
                                .animation(.spring(duration: 0.3), value: currentStep)
                        }
                    }
                    .padding(.top, 16)

                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)

                    // Step content
                    TabView(selection: $currentStep) {
                        WelcomePermissionsView()
                            .tag(0)

                        ProfileGoalsView()
                            .tag(1)

                        WeightGoalStepView()
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)

                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                dismissKeyboard()
                                withAnimation { currentStep -= 1 }
                            }
                            .buttonStyle(.bordered)
                        }

                        Spacer()

                        if currentStep < totalSteps - 1 {
                            Button("Next") {
                                dismissKeyboard()
                                withAnimation { currentStep += 1 }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Complete Setup") {
                                dismissKeyboard()
                                appState.completeOnboarding()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
