import SwiftUI

struct ActivityGoalsStepView: View {
    @Environment(AppState.self) private var appState
    @State private var dailySteps: Double = Double(AppConstants.Defaults.dailySteps)
    @State private var dailyCalories: Double = AppConstants.Defaults.dailyCalories
    @State private var checkTimeHour: Int = AppConstants.Defaults.checkTimeHour
    @State private var checkTimeMinute: Int = AppConstants.Defaults.checkTimeMinute

    private var checkTimeDisplay: String {
        let hour = checkTimeHour % 12 == 0 ? 12 : checkTimeHour % 12
        let period = checkTimeHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour, checkTimeMinute, period)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("Daily Activity Goals")
                        .font(.title.bold())

                    Text("Set your daily targets for steps and active calories.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Steps goal
                VStack(alignment: .leading, spacing: 8) {
                    Label("Daily Steps", systemImage: "figure.walk")
                        .font(.headline)

                    HStack {
                        Slider(value: $dailySteps, in: 1000...30000, step: 500)
                            .tint(.green)
                        Text(UnitConverter.stepString(Int(dailySteps)))
                            .font(.headline)
                            .monospacedDigit()
                            .frame(width: 80, alignment: .trailing)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Calories goal
                VStack(alignment: .leading, spacing: 8) {
                    Label("Active Calories", systemImage: "flame.fill")
                        .font(.headline)

                    HStack {
                        Slider(value: $dailyCalories, in: 100...2000, step: 25)
                            .tint(.orange)
                        Text("\(Int(dailyCalories)) kcal")
                            .font(.headline)
                            .monospacedDigit()
                            .frame(width: 80, alignment: .trailing)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Check time — using Stepper pickers instead of DatePicker wheel
                VStack(alignment: .leading, spacing: 8) {
                    Label("Check Time", systemImage: "clock.fill")
                        .font(.headline)

                    Text("After this time, you'll get a warning if goals aren't met.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Time:")
                        Spacer()
                        Text(checkTimeDisplay)
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }

                    Stepper("Hour: \(checkTimeHour % 12 == 0 ? 12 : checkTimeHour % 12) \(checkTimeHour < 12 ? "AM" : "PM")", value: $checkTimeHour, in: 0...23)

                    Stepper("Minute: \(String(format: "%02d", checkTimeMinute))", value: $checkTimeMinute, in: 0...55, step: 5)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .onChange(of: dailySteps) { _, _ in save() }
        .onChange(of: dailyCalories) { _, _ in save() }
        .onChange(of: checkTimeHour) { _, _ in save() }
        .onChange(of: checkTimeMinute) { _, _ in save() }
        .onAppear(perform: loadExisting)
    }

    private func loadExisting() {
        if let goals = appState.goals {
            dailySteps = Double(goals.dailySteps)
            dailyCalories = goals.dailyCalories
            checkTimeHour = goals.checkTimeHour
            checkTimeMinute = goals.checkTimeMinute
        }
    }

    private func save() {
        let goals = FitLockGoals(
            dailySteps: Int(dailySteps),
            dailyCalories: dailyCalories,
            checkTimeHour: checkTimeHour,
            checkTimeMinute: checkTimeMinute
        )
        appState.saveGoals(goals)
    }
}
