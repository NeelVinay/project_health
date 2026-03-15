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
            // Expected line (dashed)
            ForEach(displayData) { point in
                LineMark(
                    x: .value("Week", point.weekNumber),
                    y: .value("Expected", displayWeight(point.expectedWeightKg))
                )
                .foregroundStyle(.teal.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .interpolationMethod(.catmullRom)
            }

            // Actual line (solid)
            ForEach(displayData.filter { $0.actualWeightKg != nil }) { point in
                LineMark(
                    x: .value("Week", point.weekNumber),
                    y: .value("Actual", displayWeight(point.actualWeightKg!))
                )
                .foregroundStyle(pointColor(point))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(pointColor(point))
                        .frame(width: 6, height: 6)
                }
            }

            // Area between expected and actual
            ForEach(displayData.filter { $0.actualWeightKg != nil }) { point in
                AreaMark(
                    x: .value("Week", point.weekNumber),
                    yStart: .value("Expected", displayWeight(point.expectedWeightKg)),
                    yEnd: .value("Actual", displayWeight(point.actualWeightKg!))
                )
                .foregroundStyle(
                    areaColor(point).opacity(0.1)
                )
            }

            // Target weight line
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

            // Checkpoint markers
            if !compact {
                ForEach(displayData.filter { $0.isCheckpoint && $0.hasActualData }) { point in
                    RuleMark(x: .value("Checkpoint", point.weekNumber))
                        .foregroundStyle(.purple.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
        }
        .chartXAxisLabel(compact ? "" : "Week")
        .chartYAxisLabel(compact ? "" : (useMetric ? "kg" : "lbs"))
        .chartXAxis(compact ? .hidden : .automatic)
        .chartYAxis(compact ? .hidden : .automatic)
        .frame(height: compact ? 120 : 300)
    }

    private func pointColor(_ point: WeightProjectionPoint) -> Color {
        guard let actual = point.actualWeightKg else { return .blue }
        let diff = actual - point.expectedWeightKg
        // For fat loss, being below expected is good
        // For weight gain, being above expected is good
        return abs(diff) < 0.5 ? .green : .orange
    }

    private func areaColor(_ point: WeightProjectionPoint) -> Color {
        guard let actual = point.actualWeightKg else { return .clear }
        let diff = actual - point.expectedWeightKg
        return abs(diff) < 0.5 ? .green : .red
    }
}
