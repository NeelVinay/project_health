import SwiftUI
import Charts

struct WeightTrendChart: View {
    let projectionData: [WeightProjectionPoint]
    let targetWeightKg: Double
    let useMetric: Bool
    let compact: Bool

    init(
        projectionData: [WeightProjectionPoint],
        targetWeightKg: Double,
        useMetric: Bool = true,
        compact: Bool = false
    ) {
        self.projectionData = projectionData
        self.targetWeightKg = targetWeightKg
        self.useMetric = useMetric
        self.compact = compact
    }

    private var displayData: [WeightProjectionPoint] {
        compact ? Array(projectionData.suffix(8)) : projectionData
    }

    private func displayWeight(_ kg: Double) -> Double {
        useMetric ? kg : UnitConverter.kgToLbs(kg)
    }

    private var displayTargetWeight: Double {
        displayWeight(targetWeightKg)
    }

    var body: some View {
        Chart {
            // Expected line (dashed teal)
            ForEach(displayData) { point in
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
            ForEach(displayData.filter { $0.actualWeightKg != nil }) { point in
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
                        .frame(width: 6, height: 6)
                }
            }

            // Goal target line (green dashed)
            RuleMark(y: .value("Target", displayTargetWeight))
                .foregroundStyle(.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    if !compact {
                        Text("Goal: \(UnitConverter.weightString(targetWeightKg, useMetric: useMetric))")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
        }
        .chartXAxisLabel(compact ? "" : "Week")
        .chartYAxisLabel(compact ? "" : (useMetric ? "kg" : "lbs"))
        .chartXAxis(compact ? .hidden : .automatic)
        .chartYAxis(compact ? .hidden : .automatic)
        .frame(height: compact ? 120 : 300)
    }
}
