import SwiftUI

struct BodyDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var weekLookupText: String = ""
    @FocusState private var isLookupFocused: Bool

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    private var lookupWeekNumber: Int? {
        Int(weekLookupText)
    }

    private var lookupResult: WeightProjectionPoint? {
        guard let profile = appState.profile, let week = lookupWeekNumber, week >= 1 else { return nil }
        let projectionData = appState.weightManager.generateProjectionData(profile: profile)
        return projectionData.first(where: { $0.weekNumber == week })
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Pill navbar
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(BodyMetric.allCases) { metric in
                                    Button {
                                        withAnimation {
                                            proxy.scrollTo(metric.id, anchor: .top)
                                        }
                                    } label: {
                                        Text(metric.rawValue)
                                            .font(.subheadline.bold())
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(pillColor(for: metric), in: Capsule())
                                            .foregroundStyle(pillForeground(for: metric))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Body metric cards
                        ForEach(BodyMetric.allCases) { metric in
                            metricCard(for: metric)
                                .id(metric.id)
                        }

                        // Weight projection chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight Projection")
                                .font(.headline)
                                .padding(.horizontal)
                            ProjectionChartView()
                        }

                        // Week lookup
                        weekLookupView()

                        // Log weight button
                        NavigationLink(destination: WeightEntryView()) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Log Weight")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                        }

                        // Weight history (daily entries)
                        weightHistorySection()
                    }
                    .padding()
                }
            }
            .navigationTitle("Body")
            .task {
                await appState.refreshBodyComposition()
            }
        }
    }

    // MARK: - Metric Card Builder

    @ViewBuilder
    private func metricCard(for metric: BodyMetric) -> some View {
        let bc = appState.bodyComposition
        let history = bc.history(for: metric)
        let stats = bc.stats(for: metric)
        let currentStr = bc.current.formattedValue(for: metric, useMetric: useMetric)

        let trend: BodyMetricCard.TrendDirection = {
            guard let latest = stats.latest, let previous = stats.previous else { return .noData }
            let diff = latest - previous
            if abs(diff) < 0.01 { return .flat }
            return diff > 0 ? .up : .down
        }()

        let highStr: String? = stats.high.map { formatStat($0, metric: metric) }
        let lowStr: String? = stats.low.map { formatStat($0, metric: metric) }

        BodyMetricCard(
            metric: metric,
            currentValue: currentStr,
            history: history,
            trend: trend,
            high: highStr,
            low: lowStr,
            lastUpdated: bc.current.lastUpdated
        )
    }

    private func formatStat(_ value: Double, metric: BodyMetric) -> String {
        switch metric {
        case .weight, .leanBodyMass:
            return UnitConverter.weightString(value, useMetric: useMetric)
        case .bmi:
            return String(format: "%.1f", value)
        case .bodyFat:
            return String(format: "%.1f%%", value)
        case .bmr, .tdee:
            return "\(Int(value)) kcal"
        }
    }

    // MARK: - Pill Colors

    private func pillColor(for metric: BodyMetric) -> Color {
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

    private func pillForeground(for metric: BodyMetric) -> Color {
        .white
    }

    // MARK: - Week Lookup

    private func weekLookupView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Week Lookup", systemImage: "magnifyingglass")
                .font(.headline)

            HStack(spacing: 12) {
                HStack {
                    Text("Week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("#", text: $weekLookupText)
                        .keyboardType(.numberPad)
                        .focused($isLookupFocused)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                }

                if isLookupFocused {
                    Button("Done") {
                        isLookupFocused = false
                    }
                    .font(.subheadline.bold())
                }
            }

            if let result = lookupResult {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(UnitConverter.weightString(result.expectedWeightKg, useMetric: useMetric))
                            .font(.title3.bold())
                            .foregroundStyle(.teal)
                    }

                    if let actual = result.actualWeightKg {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Actual")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(UnitConverter.weightString(actual, useMetric: useMetric))
                                .font(.title3.bold())
                                .foregroundStyle(.blue)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Actual")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("No data yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.date.shortDateString)
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                .padding(.top, 4)
            } else if let week = lookupWeekNumber, week >= 1 {
                Text("Week \(week) is beyond the projection range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: - Weight History (Daily Entries)

    @ViewBuilder
    private func weightHistorySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Weight History", systemImage: "list.bullet")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: WeightHistoryView()) {
                    Text("See All")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            let allWeights = appState.weightManager.weeklyRecords
                .flatMap { $0.dailyWeights }
                .sorted { $0.date > $1.date }

            if allWeights.isEmpty {
                Text("No weight data yet. Log your first weight!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                // Show latest 10 entries
                ForEach(Array(allWeights.prefix(10))) { entry in
                    HStack {
                        Text(entry.date.shortDateString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(UnitConverter.weightString(entry.weightKg, useMetric: useMetric))
                            .font(.subheadline.bold())
                            .monospacedDigit()
                        Image(systemName: entry.source == .healthKit ? "applewatch" : "hand.draw")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
