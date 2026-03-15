import SwiftUI

struct PermissionsStepView: View {
    @Environment(AppState.self) private var appState
    @State private var healthKitGranted = false
    @State private var notificationsGranted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Permissions")
                        .font(.title.bold())

                    Text("FitLock needs a few permissions to track your fitness goals.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Permission cards
                VStack(spacing: 16) {
                    permissionCard(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Health Data",
                        description: "Read steps, active calories, and weight from Apple Health",
                        granted: healthKitGranted,
                        action: requestHealthKit
                    )

                    permissionCard(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Notifications",
                        description: "Get reminders and goal status updates",
                        granted: notificationsGranted,
                        action: requestNotifications
                    )
                }

                // Info about future blocking
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("App blocking will be available in a future update with Apple Developer Program.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    private func permissionCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
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
                    Button("Grant") {
                        action()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Permission Requests

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
