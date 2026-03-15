import SwiftUI

struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep = 0

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .tint(.blue)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                // Step content
                TabView(selection: $currentStep) {
                    PermissionsStepView()
                        .tag(0)

                    ActivityGoalsStepView()
                        .tag(1)

                    UserProfileStepView()
                        .tag(2)

                    WeightGoalStepView()
                        .tag(3)
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
                .padding()
            }
            .navigationTitle("FitLock Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
