import SwiftUI

struct ActivityProgressView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Steps ring
                VStack(spacing: 8) {
                    ProgressRing(
                        progress: appState.dailyProgress.stepsProgress,
                        lineWidth: 10,
                        gradient: Color.progressColor(for: appState.dailyProgress.stepsProgress),
                        size: 100
                    )
                    .overlay {
                        VStack(spacing: 0) {
                            Image(systemName: "figure.walk")
                                .font(.caption)
                            Text(UnitConverter.stepString(appState.dailyProgress.currentSteps))
                                .font(.system(.caption, design: .rounded).bold())
                                .monospacedDigit()
                        }
                    }

                    Text("Steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(UnitConverter.stepString(appState.dailyProgress.currentSteps)) / \(UnitConverter.stepString(appState.dailyProgress.stepsGoal))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                // Calories ring
                VStack(spacing: 8) {
                    ProgressRing(
                        progress: appState.dailyProgress.caloriesProgress,
                        lineWidth: 10,
                        gradient: Color.progressColor(for: appState.dailyProgress.caloriesProgress),
                        size: 100
                    )
                    .overlay {
                        VStack(spacing: 0) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                            Text("\(Int(appState.dailyProgress.currentCalories))")
                                .font(.system(.caption, design: .rounded).bold())
                                .monospacedDigit()
                        }
                    }

                    Text("Active Cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Int(appState.dailyProgress.currentCalories)) / \(Int(appState.dailyProgress.caloriesGoal)) kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
