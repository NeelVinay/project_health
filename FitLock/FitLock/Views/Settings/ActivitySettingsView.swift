import SwiftUI

struct ActivitySettingsView: View {
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

            Section(header: Text("Check Time"), footer: Text("After this time, you'll get a notification if goals aren't met.")) {
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
        }
        .navigationTitle("Activity Goals")
        .onAppear(perform: load)
        .onChange(of: dailySteps) { _, _ in save() }
        .onChange(of: dailyCalories) { _, _ in save() }
        .onChange(of: checkTimeHour) { _, _ in save() }
        .onChange(of: checkTimeMinute) { _, _ in save() }
    }

    private func load() {
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

        // Re-schedule notifications with updated check time
        let notifications = NotificationManager()
        notifications.schedulePreLockWarning(checkHour: checkTimeHour, checkMinute: checkTimeMinute)
        notifications.scheduleGoalsUnmetNotification(checkHour: checkTimeHour, checkMinute: checkTimeMinute)
    }
}
