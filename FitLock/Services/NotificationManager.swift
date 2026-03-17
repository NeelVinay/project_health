import Foundation
import UserNotifications
import Observation

@Observable
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    var isAuthorized = false

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermission() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Daily Notifications

    func scheduleAfternoonProgress(steps: Int, stepsGoal: Int, calories: Double, caloriesGoal: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Afternoon Check-in"
        content.body = "You're at \(UnitConverter.stepString(steps)) steps and \(Int(calories)) cal — keep going!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 15 // 3 PM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notifications.afternoonProgress,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Schedule a daily warning at 11 PM (23:00) — 1 hour before midnight.
    func schedulePreMidnightWarning() {
        // Remove any existing one first so we don't duplicate
        cancelNotification(id: AppConstants.Notifications.preLockWarning)

        let content = UNMutableNotificationContent()
        content.title = "1 Hour Until Midnight"
        content.body = "1 hour until midnight! Keep moving to hit your goals before the day ends."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 23
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notifications.preLockWarning,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Immediate Notifications

    /// Fires immediately when midnight reset detects yesterday's goals were not met.
    func sendGoalsUnmetAtMidnight() {
        sendImmediate(
            id: AppConstants.Notifications.goalsUnmetCheckTime,
            title: "Goals Not Met",
            body: "You didn't meet your goals today. In future updates, social media will be blocked."
        )
    }

    func sendLockActivated() {
        sendImmediate(
            id: AppConstants.Notifications.lockActivated,
            title: "Social Media Locked",
            body: "Goals not met — social media is locked. Complete your activity goals to unlock."
        )
    }

    func sendGoalsAchieved() {
        sendImmediate(
            id: AppConstants.Notifications.goalsAchieved,
            title: "Goals Achieved!",
            body: "Great job! You hit your step and calorie goals today. Apps are unlocked."
        )
    }

    func sendWeeklyWeightWarning() {
        sendImmediate(
            id: AppConstants.Notifications.weeklyWeightWarning,
            title: "Weight Trend Warning",
            body: "Your weight this week didn't meet the target. One more week off track will lock social media."
        )
    }

    func sendWeeklyWeightLock() {
        sendImmediate(
            id: AppConstants.Notifications.weeklyWeightLock,
            title: "Weight Off Track — Apps Locked",
            body: "Weight trend off track for 2 weeks. Social media locked until next weekly check shows improvement."
        )
    }

    func sendCheckpointAdjustment(weekNumber: Int) {
        sendImmediate(
            id: AppConstants.Notifications.checkpoint,
            title: "4-Week Checkpoint",
            body: "Your metabolism has adapted. Adjusting your targets — check the app for updated goals."
        )
    }

    func sendWeightEntryReminder() {
        sendImmediate(
            id: AppConstants.Notifications.weightEntryReminder,
            title: "Log Your Weight",
            body: "Don't forget to weigh in this week! Consistent tracking helps you stay on track."
        )
    }

    // MARK: - Cancel

    /// Cancel the goals unmet notification (call this when goals ARE met before check time)
    func cancelGoalsUnmetNotification() {
        cancelNotification(id: AppConstants.Notifications.goalsUnmetCheckTime)
    }

    // MARK: - Re-Sign Reminder

    func scheduleResignReminder(installDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Re-deploy FitLock"
        content.body = "Re-deploy FitLock from Xcode tomorrow to keep blocking active. Your 7-day signing period is almost up."
        content.sound = .default

        let resignDate = Calendar.current.date(byAdding: .day, value: AppConstants.Defaults.resignReminderDays, to: installDate)!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: resignDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notifications.resignReminder,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Helpers

    private func sendImmediate(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request)
    }
}
