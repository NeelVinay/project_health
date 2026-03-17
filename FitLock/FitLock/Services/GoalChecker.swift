import Foundation
import Observation

@Observable
final class GoalChecker {
    private let healthKit: HealthKitManager
    private let weightManager: WeightManager
    private let storage: GoalStorage

    var lastEvaluationResult: EvaluationResult?

    init(healthKit: HealthKitManager, weightManager: WeightManager, storage: GoalStorage) {
        self.healthKit = healthKit
        self.weightManager = weightManager
        self.storage = storage
    }

    struct EvaluationResult {
        var dailyGoalsMet: Bool
        var weightOnTrack: Bool
        var shouldWarn: Bool
        var warnReason: WarnReason?
    }

    enum WarnReason: String {
        case dailyGoalsUnmet = "Daily activity goals not met"
        case weightOffTrack = "Weight off track for 2+ consecutive weeks"
        case both = "Daily goals unmet and weight off track"
    }

    // MARK: - Full Evaluation

    func evaluate() async -> EvaluationResult {
        await healthKit.refreshAll()

        let goals = storage.loadGoals() ?? FitLockGoals()
        let profile = storage.loadProfile()

        // Check daily goals
        let stepsGoalMet = healthKit.todaySteps >= goals.dailySteps
        let caloriesGoalMet = healthKit.todayCalories >= goals.dailyCalories
        let dailyGoalsMet = stepsGoalMet && caloriesGoalMet

        // Check weight (only if past baseline period)
        let weightOffTrack: Bool
        if let profile, profile.currentWeekNumber > AppConstants.Defaults.baselineWeeks {
            weightOffTrack = weightManager.shouldLockForWeight()
        } else {
            weightOffTrack = false
        }

        // Warning state is based on yesterday's unmet goals (persisted in isDailyLocked)
        // or current weight being off track
        let weightWarnNeeded = weightOffTrack
        let shouldWarn = storage.isDailyLocked || weightWarnNeeded

        let warnReason: WarnReason?
        if storage.isDailyLocked && weightWarnNeeded {
            warnReason = .both
        } else if storage.isDailyLocked {
            warnReason = .dailyGoalsUnmet
        } else if weightWarnNeeded {
            warnReason = .weightOffTrack
        } else {
            warnReason = nil
        }

        let result = EvaluationResult(
            dailyGoalsMet: dailyGoalsMet,
            weightOnTrack: !weightOffTrack,
            shouldWarn: shouldWarn,
            warnReason: warnReason
        )

        lastEvaluationResult = result
        storage.isWeightLocked = weightWarnNeeded

        // If daily goals met today, clear any daily warning from yesterday
        if dailyGoalsMet {
            storage.isDailyLocked = false
        }

        return result
    }

    // MARK: - Midnight Reset

    /// Called at midnight (or when app opens after midnight on a new day).
    /// Evaluates whether yesterday's goals were met, sends notification if not, then resets for the new day.
    func handleMidnightReset(yesterdaySteps: Int, yesterdayCalories: Double) {
        let goals = storage.loadGoals() ?? FitLockGoals()
        let yesterdayMet = yesterdaySteps >= goals.dailySteps && yesterdayCalories >= goals.dailyCalories

        let notifications = NotificationManager()

        if !yesterdayMet {
            // Goals were NOT met yesterday — send notification and set daily warning
            storage.isDailyLocked = true
            notifications.sendGoalsUnmetAtMidnight()
        } else {
            // Goals were met — clear any daily warning
            storage.isDailyLocked = false
        }
    }

    // MARK: - First Day Check

    func isFirstDay() -> Bool {
        guard let profile = storage.loadProfile() else { return true }
        return Calendar.current.isDateInToday(profile.startDate)
    }
}
