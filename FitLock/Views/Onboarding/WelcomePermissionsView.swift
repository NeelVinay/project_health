import SwiftUI

struct WelcomePermissionsView: View {
    @Environment(AppState.self) private var appState
    @State private var healthKitGranted = false
    @State private var notificationsGranted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                // App icon / illustration
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Welcome to FitLock")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text("Track your fitness goals, monitor body composition, and stay accountable.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Permission cards with modern style
                VStack(spacing: 16) {
                    permissionRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Health Data",
                        description: "Steps, calories, weight & body composition",
                        granted: healthKitGranted
                    ) {
                        requestHealthKit()
                    }

                    permissionRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Notifications",
                        description: "Goal reminders & progress updates",
                        granted: notificationsGranted
                    ) {
                        requestNotifications()
                    }
                }
                .padding(.horizontal)

                // Quick grant all button
                if !healthKitGranted || !notificationsGranted {
                    Button {
                        requestHealthKit()
                        requestNotifications()
                    } label: {
                        Text("Grant All Permissions")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                }

                // Info note
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("App blocking coming in a future update.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
    }

    private func permissionRow(icon: String, iconColor: Color, title: String, description: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private func requestHealthKit() {
        Task {
            do {
                try await appState.healthKit.requestAuthorization()
                healthKitGranted = true
            } catch {
                print("HealthKit auth error: \(error)")
            }
        }
    }

    private func requestNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                notificationsGranted = granted
            } catch {
                print("Notification auth error: \(error)")
            }
        }
    }
}
