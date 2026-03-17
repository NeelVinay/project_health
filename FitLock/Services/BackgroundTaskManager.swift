import Foundation
import BackgroundTasks

enum BackgroundTaskManager {

    // MARK: - Registration

    static func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppConstants.BackgroundTasks.goalCheck,
            using: nil
        ) { task in
            handleGoalCheck(task as! BGAppRefreshTask)
        }
    }

    // MARK: - Scheduling

    static func scheduleGoalCheck() {
        let request = BGAppRefreshTaskRequest(identifier: AppConstants.BackgroundTasks.goalCheck)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule goal check background task: \(error)")
        }
    }

    // MARK: - Handling

    private static func handleGoalCheck(_ task: BGAppRefreshTask) {
        // Schedule the next check immediately
        scheduleGoalCheck()

        // Create minimal services for background evaluation
        let storage = GoalStorage()
        let healthKit = HealthKitManager()
        let weightManager = WeightManager(storage: storage)
        let goalChecker = GoalChecker(
            healthKit: healthKit,
            weightManager: weightManager,
            storage: storage
        )

        let taskOperation = Task {
            let result = await goalChecker.evaluate()

            // Send notifications based on result
            let notifications = NotificationManager()
            if result.shouldWarn && !storage.isAnyLockActive {
                // Warning just activated
                if result.warnReason == .weightOffTrack || result.warnReason == .both {
                    notifications.sendWeeklyWeightLock()
                } else {
                    notifications.sendLockActivated()
                }
            } else if !result.shouldWarn && storage.isAnyLockActive {
                // Warning just cleared
                notifications.sendGoalsAchieved()
            }
        }

        task.expirationHandler = {
            taskOperation.cancel()
        }

        Task {
            await taskOperation.value
            task.setTaskCompleted(success: true)
        }
    }
}
