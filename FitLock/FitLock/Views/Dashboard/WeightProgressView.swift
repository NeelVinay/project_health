import SwiftUI

struct WeightProgressView: View {
    @Environment(AppState.self) private var appState

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Label("Weight Journey", systemImage: "scalemass.fill")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: WeightHistoryView()) {
                    Text("History")
                        .font(.caption)
                }
            }

            if let profile = appState.profile {
                // Current weight + trend
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(UnitConverter.weightString(profile.currentWeightKg, useMetric: useMetric))
                            .font(.title.bold())
                    }

                    Spacer()

                    // Weekly change
                    if let latestRecord = appState.weightManager.weeklyRecords.last(where: { $0.actualChangeKg != nil }),
                       let change = latestRecord.actualChangeKg {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("This Week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                                    .font(.caption)
                                Text(UnitConverter.weightString(abs(change), useMetric: useMetric, decimals: 2))
                                    .font(.headline.bold())
                            }
                            .foregroundStyle(trendColor(change: change, goalType: profile.goalType))
                        }
                    }
                }

                // Journey info
                HStack {
                    infoChip("Week \(profile.currentWeekNumber)", icon: "calendar")
                    Spacer()
                    let nextCheckpoint = nextCheckpointWeeks(profile: profile)
                    if nextCheckpoint > 0 {
                        infoChip("Checkpoint in \(nextCheckpoint)w", icon: "flag")
                    }
                    Spacer()
                    infoChip("Goal: \(UnitConverter.weightString(profile.targetWeightKg, useMetric: useMetric))", icon: "target")
                }

                // Mini chart
                let projectionData = appState.weightManager.generateProjectionData(profile: profile)
                if !projectionData.isEmpty {
                    WeightTrendChart(
                        projectionData: projectionData,
                        targetWeightKg: profile.targetWeightKg,
                        useMetric: useMetric,
                        compact: true
                    )
                }
            } else {
                Text("Complete onboarding to set up weight tracking")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func infoChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    private func trendColor(change: Double, goalType: GoalType) -> Color {
        switch goalType {
        case .fatLoss:
            return change <= 0 ? .green : .red
        case .weightGain:
            return change >= 0 ? .green : .red
        }
    }

    private func nextCheckpointWeeks(profile: UserProfile) -> Int {
        let currentWeek = profile.currentWeekNumber
        let interval = AppConstants.Defaults.checkpointIntervalWeeks
        let nextCheckpoint = ((currentWeek / interval) + 1) * interval
        return nextCheckpoint - currentWeek
    }
}
