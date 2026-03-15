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
        var isPastCheckTime: Bool
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
        // Refresh health data
        await healthKit.refreshAll()

        let goals = storage.loadGoals() ?? FitLockGoals()
        let profile = storage.loadProfile()

        // Check daily goals
        let stepsGoalMet = healthKit.todaySteps >= goals.dailySteps
        let caloriesGoalMet = healthKit.todayCalories >= goals.dailyCalories
        let dailyGoalsMet = stepsGoalMet && caloriesGoalMet

        // Check time
        let isPastCheckTime = Date.isPastTime(hour: goals.checkTimeHour, minute: goals.checkTimeMinute)

        // Check weight (only if we're past the baseline period)
        let weightOffTrack: Bool
        if let profile, profile.currentWeekNumber > AppConstants.Defaults.baselineWeeks {
            weightOffTrack = weightManager.shouldLockForWeight()
        } else {
            weightOffTrack = false
        }

        // Determine warning state (no blocking in tracker-only mode)
        let dailyWarnNeeded = isPastCheckTime && !dailyGoalsMet
        let weightWarnNeeded = weightOffTrack
        let shouldWarn = dailyWarnNeeded || weightWarnNeeded

        let warnReason: WarnReason?
        if dailyWarnNeeded && weightWarnNeeded {
            warnReason = .both
        } else if dailyWarnNeeded {
            warnReason = .dailyGoalsUnmet
        } else if weightWarnNeeded {
            warnReason = .weightOffTrack
        } else {
            warnReason = nil
        }

        let result = EvaluationResult(
            dailyGoalsMet: dailyGoalsMet,
            isPastCheckTime: isPastCheckTime,
            weightOnTrack: !weightOffTrack,
            shouldWarn: shouldWarn,
            warnReason: warnReason
        )

        lastEvaluationResult = result

        // Update storage state
        storage.isDailyLocked = isPastCheckTime && !dailyGoalsMet
        storage.isWeightLocked = weightWarnNeeded

        // If daily goals met at any point, clear daily warning
        if dailyGoalsMet {
            storage.isDailyLocked = false
        }

        return result
    }

    // MARK: - Midnight Reset

    func handleMidnightReset() {
        // Clear daily warning — weight warning persists
        storage.isDailyLocked = false
    }

    // MARK: - First Day Check

    func isFirstDay() -> Bool {
        guard let profile = storage.loadProfile() else { return true }
        return Calendar.current.isDateInToday(profile.startDate)
    }
}
