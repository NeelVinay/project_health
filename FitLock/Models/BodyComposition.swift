import Foundation

// MARK: - Body Metric Enum

enum BodyMetric: String, CaseIterable, Identifiable {
    case weight = "Weight"
    case bmi = "BMI"
    case bodyFat = "Body Fat"
    case leanBodyMass = "Lean Mass"
    case bmr = "BMR"
    case tdee = "TDEE"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .weight: return "kg"
        case .bmi: return ""
        case .bodyFat: return "%"
        case .leanBodyMass: return "kg"
        case .bmr: return "kcal"
        case .tdee: return "kcal"
        }
    }

    var imperialUnit: String {
        switch self {
        case .weight: return "lbs"
        case .bmi: return ""
        case .bodyFat: return "%"
        case .leanBodyMass: return "lbs"
        case .bmr: return "kcal"
        case .tdee: return "kcal"
        }
    }

    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .bmi: return "figure.stand"
        case .bodyFat: return "drop.fill"
        case .leanBodyMass: return "figure.strengthtraining.traditional"
        case .bmr: return "flame.fill"
        case .tdee: return "bolt.fill"
        }
    }

    var color: String {
        switch self {
        case .weight: return "blue"
        case .bmi: return "purple"
        case .bodyFat: return "orange"
        case .leanBodyMass: return "green"
        case .bmr: return "red"
        case .tdee: return "teal"
        }
    }

    /// Whether this metric needs HealthKit data (vs being calculated)
    var isFromHealthKit: Bool {
        switch self {
        case .weight, .bmi, .bodyFat, .leanBodyMass: return true
        case .bmr, .tdee: return false
        }
    }
}

// MARK: - Body Composition Snapshot

struct BodyComposition {
    var weight: Double?             // kg
    var bmi: Double?                // dimensionless
    var bodyFatPercentage: Double?  // 0.0-1.0 from HealthKit, displayed as %
    var leanBodyMass: Double?       // kg
    var bmr: Double?                // kcal/day
    var tdee: Double?               // kcal/day
    var lastUpdated: Date?

    func value(for metric: BodyMetric) -> Double? {
        switch metric {
        case .weight: return weight
        case .bmi: return bmi
        case .bodyFat:
            // Convert from fraction to percentage for display
            guard let bf = bodyFatPercentage else { return nil }
            return bf * 100.0
        case .leanBodyMass: return leanBodyMass
        case .bmr: return bmr
        case .tdee: return tdee
        }
    }

    func formattedValue(for metric: BodyMetric, useMetric: Bool) -> String {
        guard let val = value(for: metric) else { return "—" }
        switch metric {
        case .weight:
            return UnitConverter.weightString(val, useMetric: useMetric)
        case .bmi:
            return String(format: "%.1f", val)
        case .bodyFat:
            return String(format: "%.1f%%", val)
        case .leanBodyMass:
            return UnitConverter.weightString(val, useMetric: useMetric)
        case .bmr, .tdee:
            return "\(Int(val)) kcal"
        }
    }
}

// MARK: - Body Metric Sample (for charts)

struct BodyMetricSample: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
