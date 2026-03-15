import Foundation
import Observation
import SwiftUI

@Observable
final class AppState {
    let storage: GoalStorage
    let healthKit: HealthKitManager
    let weightManager: WeightManager
    let goalChecker: GoalChecker

    // This is the observable flag that drives the UI transition
    var isOnboardingComplete: Bool = false

    init() {
        let storage = GoalStorage()
        let healthKit = HealthKitManager()
        let weightManager = WeightManager(storage: storage)
        let goalChecker = GoalChecker(
            healthKit: healthKit,
            weightManager: weightManager,
            storage: storage
        )
        self.storage = storage
        self.healthKit = healthKit
        self.weightManager = weightManager
        self.goalChecker = goalChecker
        self.isOnboardingComplete = storage.isOnboardingCompleted
    }

    var profile: UserProfile?
    var goals: FitLockGoals?
    var dailyProgress = DailyProgress()
    var isLoading = false

    // Warning state (tracker-only mode — no blocking)
    var isDailyWarning: Bool {
        get { storage.isDailyLocked }
        set { storage.isDailyLocked = newValue }
    }

    var isWeightWarning: Bool {
        get { storage.isWeightLocked }
        set { storage.isWeightLocked = newValue }
    }

    var hasActiveWarning: Bool {
        isDailyWarning || isWeightWarning
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        storage.isOnboardingCompleted = true
        loadAll()
        isOnboardingComplete = true
    }

    // MARK: - Initialization

    func loadAll() {
        profile = storage.loadProfile()
        goals = storage.loadGoals()
        weightManager.reload()
    }

    // MARK: - Save Helpers

    func saveProfile(_ profile: UserProfile) {
        self.profile = profile
        storage.saveProfile(profile)
    }

    func saveGoals(_ goals: FitLockGoals) {
        self.goals = goals
        storage.saveGoals(goals)
    }

    // MARK: - HealthKit Refresh

    func refreshHealthData() async {
        isLoading = true
        defer { isLoading = false }

        await healthKit.refreshAll()

        let stepsGoal = goals?.dailySteps ?? AppConstants.Defaults.dailySteps
        let caloriesGoal = goals?.dailyCalories ?? AppConstants.Defaults.dailyCalories

        dailyProgress = DailyProgress(
            date: Date(),
            currentSteps: healthKit.todaySteps,
            currentCalories: healthKit.todayCalories,
            stepsGoal: stepsGoal,
            caloriesGoal: caloriesGoal,
            isLocked: hasActiveWarning
        )
    }

    // MARK: - Goal Evaluation

    func evaluateGoals() async {
        // Don't warn on first day
        if goalChecker.isFirstDay() {
            await refreshHealthData()
            return
        }

        let result = await goalChecker.evaluate()

        // Update daily progress
        let stepsGoal = goals?.dailySteps ?? AppConstants.Defaults.dailySteps
        let caloriesGoal = goals?.dailyCalories ?? AppConstants.Defaults.dailyCalories

        dailyProgress = DailyProgress(
            date: Date(),
            currentSteps: healthKit.todaySteps,
            currentCalories: healthKit.todayCalories,
            stepsGoal: stepsGoal,
            caloriesGoal: caloriesGoal,
            isLocked: result.shouldWarn
        )
    }

    // MARK: - Midnight Reset

    func checkMidnightReset() {
        let lastCheck = storage.lastCheckDate
        let now = Date()

        if let lastCheck, !Calendar.current.isDate(lastCheck, inSameDayAs: now) {
            // New day — reset daily warning, keep weight warning
            goalChecker.handleMidnightReset()
            dailyProgress = DailyProgress()
        }

        storage.lastCheckDate = now
    }
}
