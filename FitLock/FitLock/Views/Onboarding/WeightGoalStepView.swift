import SwiftUI

struct WeightGoalStepView: View {
    @Environment(AppState.self) private var appState
    @FocusState private var isFieldFocused: Bool

    @State private var goalType: GoalType = .fatLoss
    @State private var targetWeightValue: Double = 70.0
    @State private var timeframeWeeks: Int = 20
    @State private var selectedPace: PacePreset = .medium
    @State private var customRate: Double = 0.5
    @State private var useCustomRate = false
    @State private var warnings: [HealthWarning] = []
    @State private var dismissedWarnings: Set<UUID> = []

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    private var currentWeightKg: Double {
        appState.profile?.currentWeightKg ?? 80.0
    }

    private var effectiveRateKgPerWeek: Double {
        useCustomRate ? customRate : selectedPace.rateKgPerWeek(for: goalType)
    }

    private var requiredRate: Double {
        let totalChange = abs(targetWeightKg - currentWeightKg)
        return totalChange / Double(max(1, timeframeWeeks))
    }

    private var targetWeightKg: Double {
        UnitConverter.toKg(targetWeightValue, useMetric: useMetric)
    }

    private var projectedDate: Date {
        MetabolismCalculator.projectedCompletionDate(
            from: Date(),
            currentWeight: currentWeightKg,
            targetWeight: targetWeightKg,
            paceKgPerWeek: effectiveRateKgPerWeek
        )
    }

    private var rateSafetyColor: Color {
        if effectiveRateKgPerWeek <= 0.3 { return .green }
        if effectiveRateKgPerWeek <= 0.7 { return .yellow }
        return .red
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundStyle(.teal)

                    Text("Weight Goal")
                        .font(.title.bold())

                    Text("Set your target and we'll build a plan with adaptive pacing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Goal type
                VStack(alignment: .leading, spacing: 8) {
                    Label("Goal Type", systemImage: "target")
                        .font(.headline)

                    Picker("Goal", selection: $goalType) {
                        ForEach(GoalType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Target weight
                VStack(alignment: .leading, spacing: 8) {
                    Label("Target Weight", systemImage: "scalemass")
                        .font(.headline)

                    HStack {
                        TextField("Target", value: $targetWeightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)
                        Text(useMetric ? "kg" : "lbs")
                            .foregroundStyle(.secondary)
                    }

                    Text("Current: \(UnitConverter.weightString(currentWeightKg, useMetric: useMetric))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Timeframe
                VStack(alignment: .leading, spacing: 8) {
                    Label("Target Timeframe", systemImage: "calendar.badge.clock")
                        .font(.headline)

                    Stepper("\(timeframeWeeks) weeks (\(timeframeWeeks / 4) months)", value: $timeframeWeeks, in: 4...104)

                    if requiredRate > 0 {
                        HStack {
                            Text("Required rate: \(UnitConverter.weightString(requiredRate, useMetric: useMetric))/week")
                                .font(.caption)
                            Circle()
                                .fill(rateSafetyColor)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Pace selection
                VStack(alignment: .leading, spacing: 12) {
                    Label("Pace", systemImage: "speedometer")
                        .font(.headline)

                    ForEach(PacePreset.allCases) { preset in
                        Button {
                            selectedPace = preset
                            useCustomRate = false
                        } label: {
                            HStack {
                                Image(systemName: selectedPace == preset && !useCustomRate ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedPace == preset && !useCustomRate ? .blue : .secondary)
                                Text(preset.description(for: goalType, useMetric: useMetric))
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    // Custom rate toggle
                    Toggle("Custom rate", isOn: $useCustomRate)

                    if useCustomRate {
                        HStack {
                            TextField("Rate", value: $customRate, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .focused($isFieldFocused)
                                .frame(width: 80)
                            Text(useMetric ? "kg/week" : "lbs/week")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Projected completion
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text("Projected Completion")
                            .font(.headline)
                    }

                    Text(projectedDate.shortDateString)
                        .font(.title2.bold())
                        .foregroundStyle(.teal)

                    Text("Pace adjusts every 4 weeks for metabolic adaptation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Warnings
                ForEach(warnings) { warning in
                    if !dismissedWarnings.contains(warning.id) {
                        warningCard(warning)
                    }
                }

                // Done button when keyboard is showing
                if isFieldFocused {
                    Button("Done") {
                        isFieldFocused = false
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Transparency: show the math
                calculationBreakdown
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: effectiveRateKgPerWeek) { _, _ in recalculateWarnings(); save() }
        .onChange(of: goalType) { _, _ in recalculateWarnings(); save() }
        .onChange(of: targetWeightValue) { _, _ in recalculateWarnings(); save() }
        .onChange(of: timeframeWeeks) { _, _ in save() }
        .onChange(of: selectedPace) { _, _ in save() }
        .onChange(of: useCustomRate) { _, _ in save() }
        .onChange(of: customRate) { _, _ in save() }
        .onAppear(perform: loadExisting)
    }

    // MARK: - Warning Card

    private func warningCard(_ warning: HealthWarning) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: warning.severity == .high ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .foregroundStyle(warning.severity == .high ? .red : .orange)
                Text(warning.title)
                    .font(.headline)
                    .foregroundStyle(warning.severity == .high ? .red : .orange)
            }

            Text(warning.message)
                .font(.subheadline)

            Button("I understand, proceed anyway") {
                dismissedWarnings.insert(warning.id)
            }
            .font(.caption.bold())
            .foregroundStyle(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(warning.severity == .high ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(warning.severity == .high ? Color.red.opacity(0.3) : Color.orange.opacity(0.3))
        )
    }

    // MARK: - Calculation Breakdown (Transparency)

    @ViewBuilder
    private var calculationBreakdown: some View {
        if let profile = appState.profile {
            let bmr = MetabolismCalculator.calculateBMR(profile: profile)
            let tdee = MetabolismCalculator.calculateTDEE(profile: profile, averageSteps: 7500)
            let deficit = MetabolismCalculator.calculateDailyDeficit(paceKgPerWeek: effectiveRateKgPerWeek)
            let intake = MetabolismCalculator.targetDailyIntake(tdee: tdee, paceKgPerWeek: effectiveRateKgPerWeek, goalType: goalType)

            VStack(alignment: .leading, spacing: 6) {
                Text("The Math")
                    .font(.headline)
                    .padding(.bottom, 4)

                mathRow("BMR (Mifflin-St Jeor)", "\(Int(bmr)) kcal/day")
                mathRow("Est. TDEE", "\(Int(tdee)) kcal/day")
                mathRow(goalType == .fatLoss ? "Daily Deficit" : "Daily Surplus", "\(Int(deficit)) kcal")
                mathRow("Target Intake", "\(Int(intake)) kcal/day")
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func mathRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .monospacedDigit()
        }
    }

    // MARK: - Logic

    private func recalculateWarnings() {
        guard var profile = appState.profile else { return }
        profile.goalType = goalType
        profile.targetWeightKg = targetWeightKg
        profile.targetTimeframeWeeks = timeframeWeeks
        warnings = MetabolismCalculator.generateWarnings(profile: profile, selectedPace: effectiveRateKgPerWeek)
        dismissedWarnings.removeAll()
    }

    private func loadExisting() {
        if let profile = appState.profile {
            goalType = profile.goalType
            targetWeightValue = UnitConverter.weightValue(profile.targetWeightKg, useMetric: profile.useMetricUnits)
            timeframeWeeks = profile.targetTimeframeWeeks
            customRate = profile.selectedPaceKgPerWeek

            // Find matching preset or use custom
            let matchingPreset = PacePreset.allCases.first { preset in
                abs(preset.rateKgPerWeek(for: goalType) - profile.selectedPaceKgPerWeek) < 0.01
            }
            if let preset = matchingPreset {
                selectedPace = preset
                useCustomRate = false
            } else {
                useCustomRate = true
            }
        }
        recalculateWarnings()
    }

    private func save() {
        guard var profile = appState.profile else { return }
        profile.goalType = goalType
        profile.targetWeightKg = targetWeightKg
        profile.selectedPaceKgPerWeek = effectiveRateKgPerWeek
        profile.targetTimeframeWeeks = timeframeWeeks
        appState.saveProfile(profile)
    }
}
