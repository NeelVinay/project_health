import Foundation
import Observation

@Observable
final class BodyCompositionManager {
    private let healthKit: HealthKitManager
    private let storage: GoalStorage

    var current = BodyComposition()

    // Cache history data
    var weightHistory: [BodyMetricSample] = []
    var bmiHistory: [BodyMetricSample] = []
    var bodyFatHistory: [BodyMetricSample] = []
    var leanMassHistory: [BodyMetricSample] = []

    init(healthKit: HealthKitManager, storage: GoalStorage) {
        self.healthKit = healthKit
        self.storage = storage
    }

    // MARK: - Refresh Current Values

    func refresh(averageSteps: Int = 7500) async {
        let profile = storage.loadProfile()

        // Fetch latest values from HealthKit
        async let bodyFat = healthKit.fetchLatestBodyFat()
        async let leanMass = healthKit.fetchLatestLeanBodyMass()
        async let bmi = healthKit.fetchLatestBMI()

        let (bf, lm, b) = await (bodyFat, leanMass, bmi)

        current.weight = profile?.currentWeightKg
        current.bodyFatPercentage = bf
        current.leanBodyMass = lm
        current.bmi = b ?? profile?.bmi

        // Calculate BMR and TDEE from profile
        if let profile {
            current.bmr = MetabolismCalculator.calculateBMR(profile: profile)
            current.tdee = MetabolismCalculator.calculateTDEE(profile: profile, averageSteps: averageSteps)
        }

        current.lastUpdated = Date()
    }

    // MARK: - Fetch History

    func refreshHistory(days: Int = 30) async {
        async let wh = healthKit.fetchWeightHistory(days: days)
        async let bh = healthKit.fetchBMIHistory(days: days)
        async let bfh = healthKit.fetchBodyFatHistory(days: days)
        async let lmh = healthKit.fetchLeanBodyMassHistory(days: days)

        let (w, b, bf, lm) = await (wh, bh, bfh, lmh)
        weightHistory = w
        bmiHistory = b
        bodyFatHistory = bf
        leanMassHistory = lm
    }

    func history(for metric: BodyMetric) -> [BodyMetricSample] {
        switch metric {
        case .weight: return weightHistory
        case .bmi: return bmiHistory
        case .bodyFat:
            // Convert from fraction to percentage for display
            return bodyFatHistory.map { BodyMetricSample(date: $0.date, value: $0.value * 100.0) }
        case .leanBodyMass: return leanMassHistory
        case .bmr, .tdee: return [] // Calculated, no history
        }
    }

    /// Stats for a metric: (latest, previous, high, low)
    func stats(for metric: BodyMetric) -> (latest: Double?, previous: Double?, high: Double?, low: Double?) {
        let data = history(for: metric)
        guard !data.isEmpty else {
            let current = self.current.value(for: metric)
            return (current, nil, nil, nil)
        }
        let sorted = data.sorted { $0.date < $1.date }
        let latest = sorted.last?.value
        let previous = sorted.count >= 2 ? sorted[sorted.count - 2].value : nil
        let high = sorted.map(\.value).max()
        let low = sorted.map(\.value).min()
        return (latest, previous, high, low)
    }
}
