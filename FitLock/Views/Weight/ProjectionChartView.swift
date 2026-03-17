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
            // Tap a week to see details
            if let week = selectedWeek, let point = projectionData.first(where: { $0.weekNumber == week }) {
                tooltipView(point)
            }

            // Chart — clean two-line view
            Chart {
                // Expected line (dashed teal)
                ForEach(projectionData) { point in
                    LineMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Expected", displayWeight(point.expectedWeightKg)),
                        series: .value("Series", "Expected")
                    )
                    .foregroundStyle(.teal)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .interpolationMethod(.catmullRom)
                }

                // Actual line (solid blue)
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
                            .fill(.blue)
                            .frame(width: 7, height: 7)
                    }
                }

                // Goal target line (green dashed)
                RuleMark(y: .value("Target", displayWeight(targetWeight)))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal: \(UnitConverter.weightString(targetWeight, useMetric: useMetric))")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
            }
            .chartXAxisLabel("Week")
            .chartYAxisLabel(useMetric ? "kg" : "lbs")
            .chartXSelection(value: $selectedWeek)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 20)
            .frame(height: 300)

            // Legend
            HStack(spacing: 20) {
                legendItem(color: .teal, style: "dashed", label: "Expected")
                legendItem(color: .blue, style: "solid", label: "Actual")
                legendItem(color: .green, style: "dashed", label: "Goal")
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
}
