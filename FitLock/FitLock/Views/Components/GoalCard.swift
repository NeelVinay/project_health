import SwiftUI

struct GoalCard: View {
    let title: String
    let icon: String
    let current: String
    let goal: String
    let progress: Double
    let isMet: Bool

    var body: some View {
        HStack(spacing: 12) {
            ProgressRing(
                progress: progress,
                lineWidth: 8,
                gradient: Color.progressColor(for: progress),
                size: 56
            )
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isMet ? .green : .primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(current)
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text("/ \(goal)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isMet {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
