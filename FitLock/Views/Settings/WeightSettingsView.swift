import SwiftUI

struct WeightSettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var goalType: GoalType = .fatLoss
    @State private var targetWeightValue: Double = 70.0
    @State private var timeframeWeeks: Int = 20
    @State private var paceKgPerWeek: Double = 0.5
    @State private var warnings: [HealthWarning] = []

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    var body: some View {
        Form {
            Section("Goal Type") {
                Picker("Goal", selection: $goalType) {
                    ForEach(GoalType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Target Weight") {
                HStack {
                    TextField("Target", value: $targetWeightValue, format: .number)
                        .keyboardType(.decimalPad)
                    Text(useMetric ? "kg" : "lbs")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Timeframe") {
                Stepper("\(timeframeWeeks) weeks", value: $timeframeWeeks, in: 4...104)
            }

            Section(header: Text("Pace"), footer: Text("Your pace will automatically adjust every 4 weeks as your body adapts.")) {
                HStack {
                    TextField("Rate", value: $paceKgPerWeek, format: .number)
                        .keyboardType(.decimalPad)
                    Text(useMetric ? "kg/week" : "lbs/week")
                        .foregroundStyle(.secondary)
                }

                // Quick presets
                HStack(spacing: 8) {
                    ForEach(PacePreset.allCases) { preset in
                        Button(preset.displayName) {
                            paceKgPerWeek = preset.rateKgPerWeek(for: goalType)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            // Warnings
            if !warnings.isEmpty {
                Section("Warnings") {
                    ForEach(warnings) { warning in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(warning.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(warning.severity == .high ? .red : .orange)
                            Text(warning.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Projections
            if let profile = appState.profile {
                Section("Projections") {
                    let completionDate = MetabolismCalculator.projectedCompletionDate(
                        from: profile.startDate,
                        currentWeight: profile.currentWeightKg,
                        targetWeight: UnitConverter.toKg(targetWeightValue, useMetric: useMetric),
                        paceKgPerWeek: paceKgPerWeek
                    )
                    HStack {
                        Text("Projected Completion")
                        Spacer()
                        Text(completionDate.shortDateString)
                            .foregroundStyle(.teal)
                    }
                }
            }
        }
        .navigationTitle("Weight Goals")
        .onAppear(perform: load)
        .onDisappear(perform: save)
        .onChange(of: paceKgPerWeek) { _, _ in recalculateWarnings() }
        .onChange(of: goalType) { _, _ in recalculateWarnings() }
    }

    private func load() {
        guard let profile = appState.profile else { return }
        goalType = profile.goalType
        targetWeightValue = UnitConverter.weightValue(profile.targetWeightKg, useMetric: profile.useMetricUnits)
        timeframeWeeks = profile.targetTimeframeWeeks
        paceKgPerWeek = profile.selectedPaceKgPerWeek
        recalculateWarnings()
    }

    private func save() {
        guard var profile = appState.profile else { return }
        profile.goalType = goalType
        profile.targetWeightKg = UnitConverter.toKg(targetWeightValue, useMetric: useMetric)
        profile.targetTimeframeWeeks = timeframeWeeks
        profile.selectedPaceKgPerWeek = paceKgPerWeek
        appState.saveProfile(profile)
    }

    private func recalculateWarnings() {
        guard var profile = appState.profile else { return }
        profile.goalType = goalType
        profile.targetWeightKg = UnitConverter.toKg(targetWeightValue, useMetric: useMetric)
        warnings = MetabolismCalculator.generateWarnings(profile: profile, selectedPace: paceKgPerWeek)
    }
}
