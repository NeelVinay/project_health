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

        appState.healthKit.setupObserverQueries {
            Task { await appState.evaluateGoals() }
        }

        Task {
            await appState.healthKit.enableBackgroundDelivery()
        }

        if let installDate = appState.storage.installDate {
            let notifications = NotificationManager()
            notifications.scheduleResignReminder(installDate: installDate)
        }

        // Schedule the daily 11 PM warning (always at 23:00)
        let notifications = NotificationManager()
        notifications.schedulePreMidnightWarning()
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
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "heart.circle.fill")
                }
                .tag(0)

            BodyDashboardView()
                .tabItem {
                    Label("Body", systemImage: "figure.arms.open")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}
