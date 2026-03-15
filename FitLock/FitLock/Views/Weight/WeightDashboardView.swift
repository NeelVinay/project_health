import SwiftUI

struct WeightDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var weekLookupText: String = ""
    @FocusState private var isLookupFocused: Bool

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    private var lookupWeekNumber: Int? {
        Int(weekLookupText)
    }

    private var lookupResult: WeightProjectionPoint? {
        guard let profile = appState.profile, let week = lookupWeekNumber, week >= 1 else { return nil }
        let projectionData = appState.weightManager.generateProjectionData(profile: profile)
        return projectionData.first(where: { $0.weekNumber == week })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick stats
                    if let profile = appState.profile {
                        quickStatsView(profile)
                    }

                    // Week lookup
                    weekLookupView()

                    // Full chart
                    ProjectionChartView()

                    // Log weight button
                    NavigationLink(destination: WeightEntryView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Weight")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.blue)
                    }

                    // Metabolic insights
                    if let profile = appState.profile {
                        metabolicInsightView(profile)
                    }

                    // View history
                    NavigationLink(destination: WeightHistoryView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View Weekly History")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Weight")
        }
    }

    // MARK: - Week Lookup

    private func weekLookupView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Week Lookup", systemImage: "magnifyingglass")
                .font(.headline)

            HStack(spacing: 12) {
                HStack {
                    Text("Week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("#", text: $weekLookupText)
                        .keyboardType(.numberPad)
                        .focused($isLookupFocused)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                }

                if isLookupFocused {
                    Button("Done") {
                        isLookupFocused = false
                    }
                    .font(.subheadline.bold())
                }
            }

            if let result = lookupResult {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expected Weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(UnitConverter.weightString(result.expectedWeightKg, useMetric: useMetric))
                            .font(.title3.bold())
                            .foregroundStyle(.teal)
                    }

                    if let actual = result.actualWeightKg {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Actual Weight")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(UnitConverter.weightString(actual, useMetric: useMetric))
                                .font(.title3.bold())
                                .foregroundStyle(.blue)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Actual Weight")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("No data yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.date.shortDateString)
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                .padding(.top, 4)
            } else if let week = lookupWeekNumber, week >= 1 {
                Text("Week \(week) is beyond the projection range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func quickStatsView(_ profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            statCard(
                title: "Current",
                value: UnitConverter.weightString(profile.currentWeightKg, useMetric: useMetric),
                icon: "scalemass"
            )
            statCard(
                title: "Target",
                value: UnitConverter.weightString(profile.targetWeightKg, useMetric: useMetric),
                icon: "target"
            )

            let remaining = abs(profile.remainingWeightChangeKg)
            statCard(
                title: "Remaining",
                value: UnitConverter.weightString(remaining, useMetric: useMetric),
                icon: "arrow.down.to.line"
            )
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func metabolicInsightView(_ profile: UserProfile) -> some View {
        let bmr = MetabolismCalculator.calculateBMR(profile: profile)
        let tdee = MetabolismCalculator.calculateTDEE(profile: profile, averageSteps: 7500) // TODO: use real average
        let factor = MetabolismCalculator.adaptationFactor(weekNumber: profile.currentWeekNumber)
        let adjustedPace = MetabolismCalculator.adjustedPace(originalPace: profile.selectedPaceKgPerWeek, weekNumber: profile.currentWeekNumber)
        let intake = MetabolismCalculator.targetDailyIntake(tdee: tdee, paceKgPerWeek: adjustedPace, goalType: profile.goalType)

        return VStack(alignment: .leading, spacing: 8) {
            Label("Metabolic Insights", systemImage: "flame.fill")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("BMR").font(.caption).foregroundStyle(.secondary)
                    Text("\(Int(bmr)) kcal/day").font(.caption.bold()).monospacedDigit()
                }
                GridRow {
                    Text("TDEE").font(.caption).foregroundStyle(.secondary)
                    Text("\(Int(tdee)) kcal/day").font(.caption.bold()).monospacedDigit()
                }
                GridRow {
                    Text("Adaptation").font(.caption).foregroundStyle(.secondary)
                    Text("\(Int(factor * 100))% efficiency").font(.caption.bold()).monospacedDigit()
                }
                GridRow {
                    Text("Adjusted Pace").font(.caption).foregroundStyle(.secondary)
                    Text(UnitConverter.weightString(adjustedPace, useMetric: useMetric) + "/week").font(.caption.bold())
                }
                GridRow {
                    Text("Target Intake").font(.caption).foregroundStyle(.secondary)
                    Text("\(Int(intake)) kcal/day").font(.caption.bold()).monospacedDigit()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
