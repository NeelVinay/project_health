import SwiftUI

struct ActivitySettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var dailySteps: Double = Double(AppConstants.Defaults.dailySteps)
    @State private var dailyCalories: Double = AppConstants.Defaults.dailyCalories
    @State private var checkTime = Date()

    var body: some View {
        Form {
            Section("Step Goal") {
                VStack(alignment: .leading) {
                    Slider(value: $dailySteps, in: 1000...30000, step: 500)
                        .tint(.green)
                    Text("\(UnitConverter.stepString(Int(dailySteps))) steps/day")
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            Section("Active Calorie Goal") {
                VStack(alignment: .leading) {
                    Slider(value: $dailyCalories, in: 100...2000, step: 25)
                        .tint(.orange)
                    Text("\(Int(dailyCalories)) kcal/day")
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            Section(header: Text("Check Time"), footer: Text("After this time, if goals aren't met, selected apps will be blocked.")) {
                DatePicker(
                    "Check Time",
                    selection: $checkTime,
                    displayedComponents: .hourAndMinute
                )
            }
        }
        .navigationTitle("Activity Goals")
        .onAppear(perform: load)
        .onDisappear(perform: save)
    }

    private func load() {
        if let goals = appState.goals {
            dailySteps = Double(goals.dailySteps)
            dailyCalories = goals.dailyCalories
            checkTime = Date().atTime(hour: goals.checkTimeHour, minute: goals.checkTimeMinute)
        }
    }

    private func save() {
        let hour = Calendar.current.component(.hour, from: checkTime)
        let minute = Calendar.current.component(.minute, from: checkTime)
        let goals = FitLockGoals(
            dailySteps: Int(dailySteps),
            dailyCalories: dailyCalories,
            checkTimeHour: hour,
            checkTimeMinute: minute
        )
        appState.saveGoals(goals)
    }
}
