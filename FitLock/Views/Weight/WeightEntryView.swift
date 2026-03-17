import SwiftUI

struct WeightEntryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var weightValue: String = ""
    @State private var entryDate = Date()
    @State private var showingSaved = false

    private var useMetric: Bool {
        appState.profile?.useMetricUnits ?? true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weight input
                VStack(spacing: 12) {
                    Text("Log Your Weight")
                        .font(.title2.bold())

                    HStack(alignment: .firstTextBaseline) {
                        TextField("0.0", text: $weightValue)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)

                        Text(useMetric ? "kg" : "lbs")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    DatePicker("Date", selection: $entryDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Save button
                Button {
                    saveWeight()
                } label: {
                    Text("Save Entry")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(weightValue.isEmpty)

                if showingSaved {
                    Label("Weight saved!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }

                // Recent entries
                recentEntriesSection
            }
            .padding()
        }
        .navigationTitle("Log Weight")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var recentEntriesSection: some View {
        let entries = appState.weightManager.getCurrentWeekEntries()

        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week's Entries")
                    .font(.headline)

                ForEach(entries.sorted(by: { $0.date > $1.date })) { entry in
                    HStack {
                        Text(entry.date.shortDateString)
                            .font(.subheadline)
                        Spacer()
                        Text(UnitConverter.weightString(entry.weightKg, useMetric: useMetric))
                            .font(.subheadline.bold())
                            .monospacedDigit()
                        Image(systemName: entry.source == .healthKit ? "applewatch" : "hand.draw")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func saveWeight() {
        guard let value = Double(weightValue), value > 0 else { return }
        let weightKg = UnitConverter.toKg(value, useMetric: useMetric)

        appState.weightManager.addWeightEntry(weightKg: weightKg, source: .manual, date: entryDate)

        withAnimation {
            showingSaved = true
            weightValue = ""
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showingSaved = false }
        }
    }
}
