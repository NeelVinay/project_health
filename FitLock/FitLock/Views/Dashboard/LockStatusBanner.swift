import SwiftUI

struct LockStatusBanner: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bannerIcon)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(.subheadline.bold())
                Text(bannerSubtitle)
                    .font(.caption)
                    .opacity(0.8)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(bannerColor, in: RoundedRectangle(cornerRadius: 14))
    }

    private var bannerIcon: String {
        if appState.dailyProgress.allGoalsMet && !appState.isWeightWarning {
            return "checkmark.circle.fill"
        } else if appState.isDailyWarning {
            return "exclamationmark.triangle.fill"
        } else if appState.isWeightWarning {
            return "scalemass.fill"
        } else {
            return "figure.walk"
        }
    }

    private var bannerTitle: String {
        if appState.dailyProgress.allGoalsMet && !appState.isWeightWarning {
            return "All goals met — great job!"
        } else if appState.isDailyWarning {
            return "Yesterday's goals not met"
        } else if appState.isWeightWarning {
            return "Weight off track — stay focused!"
        } else {
            return "Keep moving to hit your goals!"
        }
    }

    private var bannerSubtitle: String {
        if appState.dailyProgress.allGoalsMet && !appState.isWeightWarning {
            return "Keep up the great work!"
        } else if appState.isDailyWarning {
            return "Hit today's targets before midnight"
        } else if appState.isWeightWarning {
            return "Check your weight goals and adjust as needed"
        } else {
            return "Hit your step and calorie targets before midnight"
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
            return .blue.opacity(0.8)
        }
    }
}
