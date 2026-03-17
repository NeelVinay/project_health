import SwiftUI
import Charts

struct MiniTrendChart: View {
    let data: [BodyMetricSample]
    var color: Color = .blue
    var height: CGFloat = 60

    var body: some View {
        if data.count >= 2 {
            Chart {
                ForEach(data) { sample in
                    LineMark(
                        x: .value("Date", sample.date),
                        y: .value("Value", sample.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", sample.date),
                        y: .value("Value", sample.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: height)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(height: height)
                .overlay {
                    Text("Not enough data")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
        }
    }
}
