import SwiftUI

struct ProfileGoalsView: View {
    @Environment(AppState.self) private var appState
    @FocusState private var isFieldFocused: Bool

    // Profile
    @State private var weightValue: Double = 80.0
    @State private var useMetric = true
    @State private var heightCm: Double = 175.0
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 9
    @State private var age: Int = 25
    @State private var biologicalSex: BiologicalSex = .male

    // Goals
    @State private var dailySteps: Double = Double(AppConstants.Defaults.dailySteps)
    @State private var dailyCalories: Double = AppConstants.Defaults.dailyCalories

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }

                    Text("Profile & Goals")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Text("Tell us about yourself and set your daily targets.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                // Unit preference
                Picker("Units", selection: $useMetric) {
                    Text("Metric (kg, cm)").tag(true)
                    Text("Imperial (lbs, ft)").tag(false)
                }
                .pickerStyle(.segmented)

                // Profile section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Profile")
                        .font(.headline)

                    // Weight
                    HStack {
                        Label("Weight", systemImage: "scalemass")
                            .font(.subheadline)
                        Spacer()
                        TextField("Weight", value: $weightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)
                            .frame(width: 80)
                        Text(useMetric ? "kg" : "lbs")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Height
                    if useMetric {
                        HStack {
                            Label("Height", systemImage: "ruler")
                                .font(.subheadline)
                            Spacer()
                            TextField("Height", value: $heightCm, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .focused($isFieldFocused)
                                .frame(width: 80)
                            Text("cm")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Label("Height", systemImage: "ruler")
                                .font(.subheadline)
                            Spacer()
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
                            }
                            .frame(width: 80)
                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                            }
                            .frame(width: 80)
                        }
                    }

                    // Age + Sex
                    Stepper("Age: \(age) years", value: $age, in: 13...100)
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biological Sex")
                            .font(.subheadline)
                        Picker("Sex", selection: $biologicalSex) {
                            ForEach(BiologicalSex.allCases) { sex in
                                Text(sex.displayName).tag(sex)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)

                // Activity Goals section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Activity Goals")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Daily Steps", systemImage: "figure.walk")
                            .font(.subheadline)
                        HStack {
                            Slider(value: $dailySteps, in: 1000...30000, step: 500)
                                .tint(.green)
                            Text(UnitConverter.stepString(Int(dailySteps)))
                                .font(.subheadline.bold())
                                .monospacedDigit()
                                .frame(width: 70, alignment: .trailing)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Active Calories", systemImage: "flame.fill")
                            .font(.subheadline)
                        HStack {
                            Slider(value: $dailyCalories, in: 100...2000, step: 25)
                                .tint(.orange)
                            Text("\(Int(dailyCalories)) kcal")
                                .font(.subheadline.bold())
                                .monospacedDigit()
                                .frame(width: 70, alignment: .trailing)
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)

                // Done button for keyboard
                if isFieldFocused {
                    Button("Done") {
                        isFieldFocused = false
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: weightValue) { _, _ in save() }
        .onChange(of: useMetric) { _, _ in save() }
        .onChange(of: heightCm) { _, _ in save() }
        .onChange(of: heightFeet) { _, _ in save() }
        .onChange(of: heightInches) { _, _ in save() }
        .onChange(of: age) { _, _ in save() }
        .onChange(of: biologicalSex) { _, _ in save() }
        .onChange(of: dailySteps) { _, _ in saveGoals() }
        .onChange(of: dailyCalories) { _, _ in saveGoals() }
        .onAppear(perform: loadExisting)
    }

    private func loadExisting() {
        if let profile = appState.profile {
            useMetric = profile.useMetricUnits
            weightValue = UnitConverter.weightValue(profile.startingWeightKg, useMetric: profile.useMetricUnits)
            heightCm = profile.heightCm
            let (ft, inch) = UnitConverter.cmToFeetInches(profile.heightCm)
            heightFeet = ft
            heightInches = inch
            age = profile.ageYears
            biologicalSex = profile.biologicalSex
        }
        if let goals = appState.goals {
            dailySteps = Double(goals.dailySteps)
            dailyCalories = goals.dailyCalories
        }
    }

    private func save() {
        let weightKg = UnitConverter.toKg(weightValue, useMetric: useMetric)
        let height = useMetric ? heightCm : UnitConverter.feetInchesToCm(feet: heightFeet, inches: heightInches)

        var profile = appState.profile ?? UserProfile()
        let isNewProfile = appState.profile == nil
        profile.startingWeightKg = weightKg
        profile.currentWeightKg = weightKg
        profile.heightCm = height
        profile.ageYears = age
        profile.biologicalSex = biologicalSex
        profile.useMetricUnits = useMetric
        if isNewProfile {
            profile.startDate = Date()
        }

        appState.saveProfile(profile)
    }

    private func saveGoals() {
        let goals = FitLockGoals(
            dailySteps: Int(dailySteps),
            dailyCalories: dailyCalories
        )
        appState.saveGoals(goals)
    }
}
