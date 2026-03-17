import SwiftUI

struct BodySnapshotView: View {
    @Environment(AppState.self) private var appState
    var onMetricTap: ((BodyMetric) -> Void)?

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let displayMetrics: [BodyMetric] = [.weight, .bodyFat, .bmi, .leanBodyMass]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Metrics")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(displayMetrics) { metric in
                    compactCard(for: metric)
                        .onTapGesture {
                            onMetricTap?(metric)
                        }
                }
            }
        }
    }

    private func compactCard(for metric: BodyMetric) -> some View {
        let value = appState.bodyComposition.current.formattedValue(for: metric, useMetric: useMetric)
        let stats = appState.bodyComposition.stats(for: metric)
        let trend: String = {
            guard let latest = stats.latest, let previous = stats.previous else { return "" }
            let diff = latest - previous
            if abs(diff) < 0.01 { return "\u{2192}" }
            return diff > 0 ? "\u{2191}" : "\u{2193}"
        }()

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .font(.caption)
                    .foregroundStyle(metricColor(metric))
                Spacer()
                if !trend.isEmpty {
                    Text(trend)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(metric.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private func metricColor(_ metric: BodyMetric) -> Color {
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
}
