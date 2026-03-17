import SwiftUI

struct ActivitySettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var dailySteps: Double = Double(AppConstants.Defaults.dailySteps)
    @State private var dailyCalories: Double = AppConstants.Defaults.dailyCalories

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
        }
        .navigationTitle("Activity Goals")
        .onAppear(perform: load)
        .onChange(of: dailySteps) { _, _ in save() }
        .onChange(of: dailyCalories) { _, _ in save() }
    }

    private func load() {
        if let goals = appState.goals {
            dailySteps = Double(goals.dailySteps)
            dailyCalories = goals.dailyCalories
        }
    }

    private func save() {
        let goals = FitLockGoals(
            dailySteps: Int(dailySteps),
            dailyCalories: dailyCalories
        )
        appState.saveGoals(goals)

        // Re-schedule the daily 11 PM warning
        let notifications = NotificationManager()
        notifications.schedulePreMidnightWarning()
    }
}
