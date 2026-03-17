import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section("Daily Activity") {
                    NavigationLink(destination: ActivitySettingsView()) {
                        Label("Steps & Calorie Goals", systemImage: "figure.walk")
                    }
                }

                Section("Weight Management") {
                    NavigationLink(destination: WeightSettingsView()) {
                        Label("Weight Goals & Pace", systemImage: "scalemass")
                    }
                }

                Section("Profile") {
                    NavigationLink(destination: ProfileSettingsView()) {
                        Label("Personal Details", systemImage: "person.fill")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    if let installDate = appState.storage.installDate {
                        let daysSinceInstall = Date().daysFrom(installDate)
                        let daysUntilResign = max(0, 7 - daysSinceInstall)
                        HStack {
                            Text("Re-sign in")
                            Spacer()
                            Text("\(daysUntilResign) days")
                                .foregroundStyle(daysUntilResign <= 1 ? .red : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Profile Settings

struct ProfileSettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var weightValue: Double = 80.0
    @State private var useMetric = true
    @State private var heightCm: Double = 175.0
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 9
    @State private var age: Int = 25
    @State private var biologicalSex: BiologicalSex = .male

    var body: some View {
        Form {
            Section("Units") {
                Picker("Unit System", selection: $useMetric) {
                    Text("Metric (kg, cm)").tag(true)
                    Text("Imperial (lbs, ft)").tag(false)
                }
            }

            Section("Body Measurements") {
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("Weight", value: $weightValue, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(useMetric ? "kg" : "lbs")
                        .foregroundStyle(.secondary)
                }

                if useMetric {
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("Height", value: $heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Height (ft)", selection: $heightFeet) {
                        ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
                    }
                    Picker("Height (in)", selection: $heightInches) {
                        ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                    }
                }
            }

            Section("Personal") {
                Stepper("Age: \(age)", value: $age, in: 13...100)

                Picker("Biological Sex", selection: $biologicalSex) {
                    ForEach(BiologicalSex.allCases) { sex in
                        Text(sex.displayName).tag(sex)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear(perform: load)
        .onDisappear(perform: save)
    }

    private func load() {
        guard let profile = appState.profile else { return }
        useMetric = profile.useMetricUnits
        weightValue = UnitConverter.weightValue(profile.startingWeightKg, useMetric: profile.useMetricUnits)
        heightCm = profile.heightCm
        let (ft, inch) = UnitConverter.cmToFeetInches(profile.heightCm)
        heightFeet = ft
        heightInches = inch
        age = profile.ageYears
        biologicalSex = profile.biologicalSex
    }

    private func save() {
        guard var profile = appState.profile else { return }
        let weightKg = UnitConverter.toKg(weightValue, useMetric: useMetric)
        let height = useMetric ? heightCm : UnitConverter.feetInchesToCm(feet: heightFeet, inches: heightInches)
        profile.startingWeightKg = weightKg
        profile.heightCm = height
        profile.ageYears = age
        profile.biologicalSex = biologicalSex
        profile.useMetricUnits = useMetric
        appState.saveProfile(profile)
    }
}
