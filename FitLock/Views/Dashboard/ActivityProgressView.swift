import SwiftUI

struct ActivityProgressView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 32) {
                // Steps ring
                VStack(spacing: 10) {
                    ProgressRing(
                        progress: appState.dailyProgress.stepsProgress,
                        lineWidth: 12,
                        gradient: Color.progressColor(for: appState.dailyProgress.stepsProgress),
                        size: 140
                    )
                    .overlay {
                        VStack(spacing: 2) {
                            Image(systemName: "figure.walk")
                                .font(.title3)
                                .foregroundStyle(.green)
                            Text(UnitConverter.stepString(appState.dailyProgress.currentSteps))
                                .font(.system(.body, design: .rounded).bold())
                                .monospacedDigit()
                        }
                    }

                    Text("Steps")
                        .font(.subheadline.bold())

                    Text("\(UnitConverter.stepString(appState.dailyProgress.currentSteps)) / \(UnitConverter.stepString(appState.dailyProgress.stepsGoal))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                // Calories ring
                VStack(spacing: 10) {
                    ProgressRing(
                        progress: appState.dailyProgress.caloriesProgress,
                        lineWidth: 12,
                        gradient: Color.progressColor(for: appState.dailyProgress.caloriesProgress),
                        size: 140
                    )
                    .overlay {
                        VStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            Text("\(Int(appState.dailyProgress.currentCalories))")
                                .font(.system(.body, design: .rounded).bold())
                                .monospacedDigit()
                        }
                    }

                    Text("Active Cal")
                        .font(.subheadline.bold())

                    Text("\(Int(appState.dailyProgress.currentCalories)) / \(Int(appState.dailyProgress.caloriesGoal)) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}
