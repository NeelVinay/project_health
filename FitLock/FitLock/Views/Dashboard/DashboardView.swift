import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var refreshTimer: Timer?
    @State private var midnightTimer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting header
                    DashboardHeaderView()

                    // Status banner (subtle)
                    LockStatusBanner()

                    // Activity progress (larger rings)
                    ActivityProgressView()

                    // Body metrics snapshot (2x2)
                    BodySnapshotView()

                    // Quick action: Log Weight
                    NavigationLink(destination: WeightEntryView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Weight")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await appState.evaluateGoals()
                await appState.refreshBodyComposition()
            }
            .task {
                await appState.evaluateGoals()
                await appState.refreshBodyComposition()
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

    // MARK: - Periodic Refresh (every 5 minutes)

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
        let calendar = Calendar.current
        let now = Date()
        guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return }
        let secondsUntilMidnight = nextMidnight.timeIntervalSince(now)

        midnightTimer = Timer.scheduledTimer(withTimeInterval: secondsUntilMidnight, repeats: false) { _ in
            appState.checkMidnightReset()
            Task { await appState.evaluateGoals() }
            scheduleMidnightReset()
        }
    }
}
