import Foundation
import Observation
import SwiftUI

@Observable
final class AppState {
    let storage: GoalStorage
    let healthKit: HealthKitManager
    let weightManager: WeightManager
    let goalChecker: GoalChecker
    let bodyComposition: BodyCompositionManager

    // This is the observable flag that drives the UI transition
    var isOnboardingComplete: Bool = false

    var selectedBodyMetric: BodyMetric?

    init() {
        let storage = GoalStorage()
        let healthKit = HealthKitManager()
        let weightManager = WeightManager(storage: storage)
        let goalChecker = GoalChecker(
            healthKit: healthKit,
            weightManager: weightManager,
            storage: storage
        )
        let bodyComposition = BodyCompositionManager(healthKit: healthKit, storage: storage)
        self.storage = storage
        self.healthKit = healthKit
        self.weightManager = weightManager
        self.goalChecker = goalChecker
        self.bodyComposition = bodyComposition
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
        Task { await refreshBodyComposition() }
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

        // Refresh body composition data
        await bodyComposition.refresh()
    }

    // MARK: - Body Composition

    func refreshBodyComposition() async {
        await bodyComposition.refresh()
        await bodyComposition.refreshHistory()
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
            // New day detected — evaluate yesterday's goals before resetting
            let yesterdaySteps = dailyProgress.currentSteps
            let yesterdayCalories = dailyProgress.currentCalories

            // Don't evaluate on first day
            if !goalChecker.isFirstDay() {
                goalChecker.handleMidnightReset(yesterdaySteps: yesterdaySteps, yesterdayCalories: yesterdayCalories)
            }

            // Reset progress to zero for the new day
            let stepsGoal = goals?.dailySteps ?? AppConstants.Defaults.dailySteps
            let caloriesGoal = goals?.dailyCalories ?? AppConstants.Defaults.dailyCalories
            dailyProgress = DailyProgress(
                date: now,
                currentSteps: 0,
                currentCalories: 0,
                stepsGoal: stepsGoal,
                caloriesGoal: caloriesGoal,
                isLocked: false
            )
        }

        storage.lastCheckDate = now
    }
}
