import SwiftUI

struct UserProfileStepView: View {
    @Environment(AppState.self) private var appState
    @FocusState private var isFieldFocused: Bool

    @State private var weightValue: Double = 80.0
    @State private var useMetric = true
    @State private var heightCm: Double = 175.0
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 9
    @State private var age: Int = 25
    @State private var biologicalSex: BiologicalSex = .male

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Your Profile")
                        .font(.title.bold())

                    Text("We need some details to calculate your metabolism and set appropriate targets.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Unit preference
                Picker("Units", selection: $useMetric) {
                    Text("Metric (kg, cm)").tag(true)
                    Text("Imperial (lbs, ft)").tag(false)
                }
                .pickerStyle(.segmented)

                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Label("Current Weight", systemImage: "scalemass")
                        .font(.headline)

                    HStack {
                        TextField("Weight", value: $weightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)

                        Text(useMetric ? "kg" : "lbs")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Label("Height", systemImage: "ruler")
                        .font(.headline)

                    if useMetric {
                        HStack {
                            TextField("Height", value: $heightCm, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .focused($isFieldFocused)
                            Text("cm")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(3...7, id: \.self) { ft in
                                    Text("\(ft) ft").tag(ft)
                                }
                            }
                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) in").tag(inch)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Label("Age", systemImage: "calendar")
                        .font(.headline)

                    Stepper("\(age) years", value: $age, in: 13...100)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Biological sex
                VStack(alignment: .leading, spacing: 8) {
                    Label("Biological Sex", systemImage: "person.2")
                        .font(.headline)

                    Text("Used for BMR calculation")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Sex", selection: $biologicalSex) {
                        ForEach(BiologicalSex.allCases) { sex in
                            Text(sex.displayName).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Done button when keyboard is showing
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
    }

    private func save() {
        let weightKg = UnitConverter.toKg(weightValue, useMetric: useMetric)
        let height = useMetric ? heightCm : UnitConverter.feetInchesToCm(feet: heightFeet, inches: heightInches)

        var profile = appState.profile ?? UserProfile()
        profile.startingWeightKg = weightKg
        profile.currentWeightKg = weightKg
        profile.heightCm = height
        profile.ageYears = age
        profile.biologicalSex = biologicalSex
        profile.useMetricUnits = useMetric
        profile.startDate = Date()

        appState.saveProfile(profile)
    }
}
