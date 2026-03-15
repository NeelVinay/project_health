import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var refreshTimer: Timer?

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
            }
            .onDisappear {
                stopPeriodicRefresh()
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
}
