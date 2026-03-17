import Foundation

struct AdaptationCheckpoint: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var weekNumber: Int
    var currentWeightKg: Double
    var recalculatedBMR: Double
    var recalculatedTDEE: Double
    var adaptationFactor: Double            // 1.0, 0.95, 0.90, ...
    var adjustedPaceKgPerWeek: Double
    var previousPaceKgPerWeek: Double
    var newProjectedCompletionDate: Date
    var dailyCalorieTarget: Double
    var previousDailyCalorieTarget: Double

    var paceChanged: Bool {
        abs(adjustedPaceKgPerWeek - previousPaceKgPerWeek) > 0.001
    }

    var completionDateString: String {
        newProjectedCompletionDate.shortDateString
    }
}
