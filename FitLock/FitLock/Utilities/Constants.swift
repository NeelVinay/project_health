import Foundation

enum AppConstants {
    static let appGroupID = "group.com.fitlock.shared"

    // MARK: - UserDefaults Keys
    enum Keys {
        static let userProfile = "fitlock_user_profile"
        static let fitLockGoals = "fitlock_goals"
        static let weeklyWeightRecords = "fitlock_weekly_weight_records"
        static let adaptationCheckpoints = "fitlock_adaptation_checkpoints"
        static let onboardingCompleted = "fitlock_onboarding_completed"
        static let blockedAppSelection = "fitlock_blocked_app_selection"
        static let dailyLockState = "fitlock_daily_lock_state"
        static let weightLockState = "fitlock_weight_lock_state"
        static let installDate = "fitlock_install_date"
        static let lastCheckDate = "fitlock_last_check_date"
    }

    // MARK: - Defaults
    enum Defaults {
        static let dailySteps = 10_000
        static let dailyCalories: Double = 550.0
        static let checkTimeHour = 21 // 9 PM
        static let checkTimeMinute = 0
        static let waterWeightTolerance = 0.3 // kg
        static let consecutiveOffTrackWeeksToLock = 2
        static let baselineWeeks = 2 // no locking during first 2 weeks
        static let checkpointIntervalWeeks = 4
        static let caloriesPerKgFat: Double = 7700.0
        static let resignReminderDays = 6
    }

    // MARK: - Background Task Identifiers
    enum BackgroundTasks {
        static let goalCheck = "com.fitlock.goalcheck"
        static let healthKitRefresh = "com.fitlock.healthkit.refresh"
    }

    // MARK: - Notification Identifiers
    enum Notifications {
        static let afternoonProgress = "fitlock.notification.afternoon"
        static let preLockWarning = "fitlock.notification.prelock"
        static let lockActivated = "fitlock.notification.locked"
        static let goalsAchieved = "fitlock.notification.achieved"
        static let weeklyWeightWarning = "fitlock.notification.weight.warning"
        static let weeklyWeightLock = "fitlock.notification.weight.lock"
        static let checkpoint = "fitlock.notification.checkpoint"
        static let resignReminder = "fitlock.notification.resign"
        static let weightEntryReminder = "fitlock.notification.weight.entry"
        static let goalsUnmetCheckTime = "fitlock.notification.goals.unmet"
    }

}
