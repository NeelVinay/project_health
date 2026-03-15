import SwiftUI
import BackgroundTasks

@main
struct FitLockApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    setupOnFirstLaunch()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        appState.checkMidnightReset()
                        Task { await appState.evaluateGoals() }
                    case .background:
                        BackgroundTaskManager.scheduleGoalCheck()
                    default:
                        break
                    }
                }
        }
    }

    init() {
        BackgroundTaskManager.registerTasks()
    }

    // MARK: - Setup

    private func setupOnFirstLaunch() {
        appState.storage.setInstallDateIfNeeded()
        appState.loadAll()

        // Set up HealthKit observer queries for background updates
        appState.healthKit.setupObserverQueries {
            Task { await appState.evaluateGoals() }
        }

        // Enable background delivery
        Task {
            await appState.healthKit.enableBackgroundDelivery()
        }

        // Schedule re-sign reminder
        if let installDate = appState.storage.installDate {
            let notifications = NotificationManager()
            notifications.scheduleResignReminder(installDate: installDate)
        }

        // Schedule daily notifications
        if let goals = appState.goals {
            let notifications = NotificationManager()
            notifications.schedulePreLockWarning(checkHour: goals.checkTimeHour, checkMinute: goals.checkTimeMinute)
        }
    }
}

// MARK: - Content View (Root Router)

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isOnboardingComplete {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "heart.circle.fill")
                }

            WeightDashboardView()
                .tabItem {
                    Label("Weight", systemImage: "scalemass.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
