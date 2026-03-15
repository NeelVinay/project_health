import SwiftUI

struct LockStatusBanner: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bannerIcon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(.headline)
                Text(bannerSubtitle)
                    .font(.caption)
                    .opacity(0.8)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .padding()
        .background(bannerColor, in: RoundedRectangle(cornerRadius: 16))
    }

    private var bannerIcon: String {
        if appState.dailyProgress.allGoalsMet && !appState.isWeightWarning {
            return "checkmark.circle.fill"
        } else if appState.isDailyWarning {
            return "exclamationmark.triangle.fill"
        } else if appState.isWeightWarning {
            return "scalemass.fill"
        } else {
            return "clock.fill"
        }
    }

    private var bannerTitle: String {
        if appState.dailyProgress.allGoalsMet && !appState.isWeightWarning {
            return "All goals met — great job!"
        } else if appState.isDailyWarning {
            return "Goals not met — keep pushing!"
        } else if appState.isWeightWarning {
            return "Weight off track — stay focused!"
        } else {
            return timeRemainingText
        }
    }

    private var bannerSubtitle: String {
        if appState.dailyProgress.allGoalsMet && !appState.isWeightWarning {
            return "Keep up the great work!"
        } else if appState.isDailyWarning {
            return "Complete your steps and calorie goals"
        } else if appState.isWeightWarning {
            return "Check your weight goals and adjust as needed"
        } else {
            return "Keep moving to hit your goals!"
        }
    }

    private var bannerColor: Color {
        if appState.dailyProgress.allGoalsMet && !appState.isWeightWarning {
            return .green
        } else if appState.isDailyWarning {
            return .red
        } else if appState.isWeightWarning {
            return .orange
        } else {
            return .yellow.opacity(0.8)
        }
    }

    private var timeRemainingText: String {
        guard let goals = appState.goals else { return "Keep moving!" }
        let checkTime = Date().atTime(hour: goals.checkTimeHour, minute: goals.checkTimeMinute)
        let now = Date()

        if now >= checkTime {
            return "Check time passed — keep moving!"
        }

        let remaining = Calendar.current.dateComponents([.hour, .minute], from: now, to: checkTime)
        let hours = remaining.hour ?? 0
        let minutes = remaining.minute ?? 0

        if hours > 0 {
            return "\(hours)h \(minutes)m until check time — keep moving!"
        } else {
            return "\(minutes)m until check time — keep moving!"
        }
    }
}
