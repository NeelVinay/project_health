import SwiftUI
import Charts

struct ProjectionChartView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedWeek: Int?

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    private var projectionData: [WeightProjectionPoint] {
        guard let profile = appState.profile else { return [] }
        return appState.weightManager.generateProjectionData(profile: profile)
    }

    private var targetWeight: Double {
        appState.profile?.targetWeightKg ?? 70
    }

    private var currentWeekNumber: Int {
        appState.profile?.currentWeekNumber ?? 1
    }

    private func displayWeight(_ kg: Double) -> Double {
        useMetric ? kg : UnitConverter.kgToLbs(kg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Selected week tooltip
            if let week = selectedWeek, let point = projectionData.first(where: { $0.weekNumber == week }) {
                tooltipView(point)
            }

            // Chart
            Chart {
                // Expected line
                ForEach(projectionData) { point in
                    let isFuture = point.weekNumber > currentWeekNumber
                    LineMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Expected", displayWeight(point.expectedWeightKg)),
                        series: .value("Series", "Expected")
                    )
                    .foregroundStyle(.teal.opacity(isFuture ? 0.4 : 0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .interpolationMethod(.catmullRom)
                }

                // Actual line
                ForEach(projectionData.filter { $0.actualWeightKg != nil }) { point in
                    LineMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Actual", displayWeight(point.actualWeightKg!)),
                        series: .value("Series", "Actual")
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle()
                            .fill(pointColor(point))
                            .frame(width: 8, height: 8)
                    }
                }

                // Area between
                ForEach(projectionData.filter { $0.actualWeightKg != nil }) { point in
                    AreaMark(
                        x: .value("Week", point.weekNumber),
                        yStart: .value("Expected", displayWeight(point.expectedWeightKg)),
                        yEnd: .value("Actual", displayWeight(point.actualWeightKg!))
                    )
                    .foregroundStyle(areaColor(point).opacity(0.08))
                }

                // Target line
                RuleMark(y: .value("Target", displayWeight(targetWeight)))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal: \(UnitConverter.weightString(targetWeight, useMetric: useMetric))")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }

                // Today marker
                RuleMark(x: .value("Today", currentWeekNumber))
                    .foregroundStyle(.blue.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .annotation(position: .top) {
                        Text("Now")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                // Checkpoint markers
                ForEach(projectionData.filter { $0.isCheckpoint }) { point in
                    RuleMark(x: .value("Checkpoint", point.weekNumber))
                        .foregroundStyle(.purple.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .chartXAxisLabel("Week")
            .chartYAxisLabel(useMetric ? "kg" : "lbs")
            .chartXSelection(value: $selectedWeek)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 20) // Show 20 weeks at a time
            .frame(height: 350)

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .teal, style: "dashed", label: "Expected")
                legendItem(color: .blue, style: "solid", label: "Actual")
                legendItem(color: .green, style: "dashed", label: "Goal")
                legendItem(color: .purple, style: "dashed", label: "Checkpoint")
            }
            .font(.caption)
        }
        .padding()
    }

    private func tooltipView(_ point: WeightProjectionPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Week \(point.weekNumber)")
                .font(.headline)
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Expected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(UnitConverter.weightString(point.expectedWeightKg, useMetric: useMetric))
                        .font(.subheadline.bold())
                }
                if let actual = point.actualWeightKg {
                    VStack(alignment: .leading) {
                        Text("Actual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(UnitConverter.weightString(actual, useMetric: useMetric))
                            .font(.subheadline.bold())
                    }
                    if let diff = point.differenceKg {
                        VStack(alignment: .leading) {
                            Text("Diff")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(diff > 0 ? "+" : "")\(UnitConverter.weightString(diff, useMetric: useMetric, decimals: 2))")
                                .font(.subheadline.bold())
                                .foregroundStyle(abs(diff) < 0.5 ? .green : .orange)
                        }
                    }
                }
            }
            if point.isCheckpoint {
                Label("Pace adjusted", systemImage: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(.purple)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func legendItem(color: Color, style: String, label: String) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: 2)
                .overlay {
                    if style == "dashed" {
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                            .foregroundStyle(color)
                    }
                }
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private func pointColor(_ point: WeightProjectionPoint) -> Color {
        guard let actual = point.actualWeightKg else { return .blue }
        let diff = actual - point.expectedWeightKg
        return abs(diff) < 0.5 ? .green : .orange
    }

    private func areaColor(_ point: WeightProjectionPoint) -> Color {
        guard let actual = point.actualWeightKg else { return .clear }
        let diff = actual - point.expectedWeightKg
        return abs(diff) < 0.5 ? .green : .red
    }
}
