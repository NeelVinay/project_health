import Foundation

struct FitLockGoals: Codable, Equatable {
    // Daily activity goals
    var dailySteps: Int = AppConstants.Defaults.dailySteps
    var dailyCalories: Double = AppConstants.Defaults.dailyCalories
    var checkTimeHour: Int = AppConstants.Defaults.checkTimeHour
    var checkTimeMinute: Int = AppConstants.Defaults.checkTimeMinute

    var checkTimeString: String {
        let hour = checkTimeHour % 12 == 0 ? 12 : checkTimeHour % 12
        let period = checkTimeHour < 12 ? "AM" : "PM"
        if checkTimeMinute == 0 {
            return "\(hour):00 \(period)"
        }
        return String(format: "%d:%02d %@", hour, checkTimeMinute, period)
    }
}
