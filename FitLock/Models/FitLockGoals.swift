import Foundation

struct FitLockGoals: Codable, Equatable {
    var dailySteps: Int = AppConstants.Defaults.dailySteps
    var dailyCalories: Double = AppConstants.Defaults.dailyCalories

    // Custom decoder to handle migration from old format that had checkTimeHour/checkTimeMinute
    init(dailySteps: Int = AppConstants.Defaults.dailySteps, dailyCalories: Double = AppConstants.Defaults.dailyCalories) {
        self.dailySteps = dailySteps
        self.dailyCalories = dailyCalories
    }

    enum CodingKeys: String, CodingKey {
        case dailySteps, dailyCalories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailySteps = try container.decodeIfPresent(Int.self, forKey: .dailySteps) ?? AppConstants.Defaults.dailySteps
        dailyCalories = try container.decodeIfPresent(Double.self, forKey: .dailyCalories) ?? AppConstants.Defaults.dailyCalories
    }
}
