import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let gradient: [Color]
    let size: CGFloat

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        gradient: [Color] = [.blue, .cyan],
        size: CGFloat = 120
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradient),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Color helpers for progress state

extension Color {
    static func progressColor(for progress: Double) -> [Color] {
        switch progress {
        case 1.0...:       return [.green, .mint]
        case 0.5..<1.0:    return [.yellow, .green]
        case 0.25..<0.5:   return [.orange, .yellow]
        default:            return [.red, .orange]
        }
    }
}
