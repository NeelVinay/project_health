import Foundation
import Observation

@Observable
final class GoalStorage {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        self.defaults = UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
    }

    // MARK: - Onboarding

    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: AppConstants.Keys.onboardingCompleted) }
        set { defaults.set(newValue, forKey: AppConstants.Keys.onboardingCompleted) }
    }

    // MARK: - User Profile

    func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: AppConstants.Keys.userProfile)
        }
    }

    func loadProfile() -> UserProfile? {
        guard let data = defaults.data(forKey: AppConstants.Keys.userProfile) else { return nil }
        return try? decoder.decode(UserProfile.self, from: data)
    }

    // MARK: - Goals

    func saveGoals(_ goals: FitLockGoals) {
        if let data = try? encoder.encode(goals) {
            defaults.set(data, forKey: AppConstants.Keys.fitLockGoals)
        }
    }

    func loadGoals() -> FitLockGoals? {
        guard let data = defaults.data(forKey: AppConstants.Keys.fitLockGoals) else { return nil }
        return try? decoder.decode(FitLockGoals.self, from: data)
    }

    // MARK: - Weekly Weight Records

    func saveWeeklyRecords(_ records: [WeeklyWeightRecord]) {
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: AppConstants.Keys.weeklyWeightRecords)
        }
    }

    func loadWeeklyRecords() -> [WeeklyWeightRecord] {
        guard let data = defaults.data(forKey: AppConstants.Keys.weeklyWeightRecords) else { return [] }
        return (try? decoder.decode([WeeklyWeightRecord].self, from: data)) ?? []
    }

    // MARK: - Adaptation Checkpoints

    func saveCheckpoints(_ checkpoints: [AdaptationCheckpoint]) {
        if let data = try? encoder.encode(checkpoints) {
            defaults.set(data, forKey: AppConstants.Keys.adaptationCheckpoints)
        }
    }

    func loadCheckpoints() -> [AdaptationCheckpoint] {
        guard let data = defaults.data(forKey: AppConstants.Keys.adaptationCheckpoints) else { return [] }
        return (try? decoder.decode([AdaptationCheckpoint].self, from: data)) ?? []
    }

    // MARK: - Lock State

    var isDailyLocked: Bool {
        get { defaults.bool(forKey: AppConstants.Keys.dailyLockState) }
        set { defaults.set(newValue, forKey: AppConstants.Keys.dailyLockState) }
    }

    var isWeightLocked: Bool {
        get { defaults.bool(forKey: AppConstants.Keys.weightLockState) }
        set { defaults.set(newValue, forKey: AppConstants.Keys.weightLockState) }
    }

    var isAnyLockActive: Bool {
        isDailyLocked || isWeightLocked
    }

    // MARK: - Install Date (for 7-day re-sign reminder)

    var installDate: Date? {
        get {
            let interval = defaults.double(forKey: AppConstants.Keys.installDate)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: AppConstants.Keys.installDate)
        }
    }

    func setInstallDateIfNeeded() {
        if installDate == nil {
            installDate = Date()
        }
    }

    // MARK: - Last Check Date

    var lastCheckDate: Date? {
        get {
            let interval = defaults.double(forKey: AppConstants.Keys.lastCheckDate)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: AppConstants.Keys.lastCheckDate)
        }
    }

    // MARK: - Reset

    func resetAll() {
        let keys = [
            AppConstants.Keys.userProfile,
            AppConstants.Keys.fitLockGoals,
            AppConstants.Keys.weeklyWeightRecords,
            AppConstants.Keys.adaptationCheckpoints,
            AppConstants.Keys.onboardingCompleted,
            AppConstants.Keys.blockedAppSelection,
            AppConstants.Keys.dailyLockState,
            AppConstants.Keys.weightLockState,
            AppConstants.Keys.installDate,
            AppConstants.Keys.lastCheckDate,
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}
