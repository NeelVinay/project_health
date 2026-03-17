import SwiftUI

struct WeightHistoryView: View {
    @Environment(AppState.self) private var appState
    @State private var collapsedWeeks: Set<Int> = []

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Full projection chart
                if let profile = appState.profile {
                    let projectionData = appState.weightManager.generateProjectionData(profile: profile)
                    if !projectionData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight Projection")
                                .font(.headline)
                            WeightTrendChart(
                                projectionData: projectionData,
                                targetWeightKg: profile.targetWeightKg,
                                useMetric: useMetric,
                                compact: false
                            )
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }

                // Weekly records list (all daily entries visible by default)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight History")
                        .font(.headline)
                        .padding(.horizontal)

                    let records = appState.weightManager.weeklyRecords.sorted { $0.weekNumber > $1.weekNumber }

                    if records.isEmpty {
                        Text("No weight data yet. Start logging your weight!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(records) { record in
                            weekRow(record)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Weight History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isExpanded: Bool { true }

    private func weekRow(_ record: WeeklyWeightRecord) -> some View {
        let isCollapsed = collapsedWeeks.contains(record.weekNumber)

        return VStack(alignment: .leading, spacing: 8) {
            // Week header (tap to collapse/expand)
            Button {
                withAnimation {
                    if isCollapsed {
                        collapsedWeeks.remove(record.weekNumber)
                    } else {
                        collapsedWeeks.insert(record.weekNumber)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week \(record.weekNumber)")
                            .font(.headline)
                        Text(record.dateRangeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Avg:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(UnitConverter.weightString(record.averageWeightKg, useMetric: useMetric))
                                .font(.headline.bold())
                                .monospacedDigit()
                        }

                        if let change = record.actualChangeKg {
                            HStack(spacing: 2) {
                                Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                                    .font(.caption2)
                                Text(UnitConverter.weightString(abs(change), useMetric: useMetric, decimals: 2))
                                    .font(.caption)
                            }
                            .foregroundStyle(changeColor(change))
                        }
                    }

                    trackIndicator(record.onTrack)

                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Daily weights — shown by default (expanded)
            if !isCollapsed {
                if record.dailyWeights.isEmpty {
                    Text("No entries this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading)
                } else {
                    Divider()

                    ForEach(record.dailyWeights.sorted(by: { $0.date > $1.date })) { entry in
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
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func trackIndicator(_ onTrack: Bool?) -> some View {
        Group {
            switch onTrack {
            case .some(true):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .some(false):
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            case .none:
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.title3)
    }

    private func changeColor(_ change: Double) -> Color {
        guard let profile = appState.profile else { return .secondary }
        switch profile.goalType {
        case .fatLoss: return change <= 0 ? .green : .red
        case .weightGain: return change >= 0 ? .green : .red
        }
    }
}
