import Foundation

struct DailyProgress {
    var date: Date = Date()
    var currentSteps: Int = 0
    var currentCalories: Double = 0.0
    var stepsGoal: Int = AppConstants.Defaults.dailySteps
    var caloriesGoal: Double = AppConstants.Defaults.dailyCalories

    var stepsGoalMet: Bool {
        currentSteps >= stepsGoal
    }

    var caloriesGoalMet: Bool {
        currentCalories >= caloriesGoal
    }

    var allGoalsMet: Bool {
        stepsGoalMet && caloriesGoalMet
    }

    var stepsProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(Double(currentSteps) / Double(stepsGoal), 1.0)
    }

    var caloriesProgress: Double {
        guard caloriesGoal > 0 else { return 0 }
        return min(currentCalories / caloriesGoal, 1.0)
    }

    var isLocked: Bool = false
}
