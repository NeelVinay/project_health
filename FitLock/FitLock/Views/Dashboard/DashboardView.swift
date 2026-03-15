import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var refreshTimer: Timer?
    @State private var midnightTimer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Lock status banner
                    LockStatusBanner()

                    // Activity progress
                    ActivityProgressView()

                    // Weight progress
                    WeightProgressView()

                    // Quick action: Log Weight
                    NavigationLink(destination: WeightEntryView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Weight")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("FitLock")
            .refreshable {
                await appState.evaluateGoals()
            }
            .task {
                await appState.evaluateGoals()
            }
            .onAppear {
                startPeriodicRefresh()
                scheduleMidnightReset()
            }
            .onDisappear {
                stopPeriodicRefresh()
                midnightTimer?.invalidate()
                midnightTimer = nil
            }
        }
    }

    // MARK: - Periodic Refresh (every 5 minutes in foreground)

    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { await appState.refreshHealthData() }
        }
    }

    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Midnight Reset Timer

    private func scheduleMidnightReset() {
        midnightTimer?.invalidate()

        // Calculate seconds until next midnight
        let calendar = Calendar.current
        let now = Date()
        guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return }
        let secondsUntilMidnight = nextMidnight.timeIntervalSince(now)

        midnightTimer = Timer.scheduledTimer(withTimeInterval: secondsUntilMidnight, repeats: false) { _ in
            // Reset at midnight
            appState.checkMidnightReset()
            Task { await appState.evaluateGoals() }
            // Schedule the next midnight reset
            scheduleMidnightReset()
        }
    }
}
