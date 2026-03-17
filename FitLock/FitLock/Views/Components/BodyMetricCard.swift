import SwiftUI

struct BodyMetricCard: View {
    let metric: BodyMetric
    let currentValue: String
    let history: [BodyMetricSample]
    let trend: TrendDirection
    let high: String?
    let low: String?
    let lastUpdated: Date?

    enum TrendDirection {
        case up, down, flat, noData

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .flat: return "arrow.right"
            case .noData: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .red
            case .down: return .green
            case .flat: return .secondary
            case .noData: return .secondary
            }
        }
    }

    private var metricColor: Color {
        switch metric.color {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "green": return .green
        case "red": return .red
        case "teal": return .teal
        default: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: icon + name + trend
            HStack {
                Image(systemName: metric.icon)
                    .font(.title3)
                    .foregroundStyle(metricColor)
                    .frame(width: 28)

                Text(metric.rawValue)
                    .font(.headline)

                Spacer()

                // Trend arrow
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.caption)
                }
                .foregroundStyle(trend == .noData ? .secondary : trendColor)
            }

            // Current value (large)
            Text(currentValue)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

            // Mini trend chart
            MiniTrendChart(data: history, color: metricColor)

            // High / Low / Last updated
            HStack {
                if let high {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("High")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(high)
                            .font(.caption.bold())
                            .monospacedDigit()
                    }
                }

                Spacer()

                if let low {
                    VStack(alignment: .center, spacing: 2) {
                        Text("Low")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(low)
                            .font(.caption.bold())
                            .monospacedDigit()
                    }
                }

                Spacer()

                if let lastUpdated {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Updated")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(lastUpdated.timeAgoString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var trendColor: Color {
        // For body fat, weight (fat loss), BMI — down is good
        // For lean mass, BMR, TDEE — up is good
        switch metric {
        case .bodyFat, .bmi:
            return trend == .down ? .green : (trend == .up ? .red : .secondary)
        case .leanBodyMass, .bmr, .tdee:
            return trend == .up ? .green : (trend == .down ? .red : .secondary)
        case .weight:
            // Depends on goal type — default to neutral
            return trend.color
        }
    }
}
