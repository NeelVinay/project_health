import Foundation

// MARK: - Enums

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male, female

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case fatLoss, weightGain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fatLoss: return "Fat Loss"
        case .weightGain: return "Weight Gain"
        }
    }
}

enum PacePreset: String, CaseIterable, Identifiable {
    case slow
    case medium
    case fast

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .medium: return "Medium"
        case .fast: return "Fast"
        }
    }

    func rateKgPerWeek(for goalType: GoalType) -> Double {
        switch (self, goalType) {
        case (.slow, _):          return 0.25
        case (.medium, _):        return 0.50
        case (.fast, .fatLoss):   return 1.00
        case (.fast, .weightGain): return 0.75
        }
    }

    func description(for goalType: GoalType, useMetric: Bool) -> String {
        let rate = rateKgPerWeek(for: goalType)
        let rateStr = UnitConverter.weightString(rate, useMetric: useMetric)
        switch self {
        case .slow:
            return "\(displayName) — \(rateStr)/week"
        case .medium:
            return "\(displayName) — \(rateStr)/week"
        case .fast:
            let note = goalType == .weightGain ? " (more fat gain expected)" : ""
            return "\(displayName) — \(rateStr)/week\(note)"
        }
    }
}

// MARK: - User Profile

struct UserProfile: Codable, Equatable {
    var startingWeightKg: Double = 80.0
    var currentWeightKg: Double = 80.0
    var targetWeightKg: Double = 70.0
    var heightCm: Double = 175.0
    var ageYears: Int = 25
    var biologicalSex: BiologicalSex = .male
    var goalType: GoalType = .fatLoss
    var selectedPaceKgPerWeek: Double = 0.5
    var targetTimeframeWeeks: Int = 20
    var startDate: Date = Date()
    var useMetricUnits: Bool = true

    // MARK: - Computed Properties

    var bmi: Double {
        let heightM = heightCm / 100.0
        return currentWeightKg / (heightM * heightM)
    }

    var totalWeightChangeKg: Double {
        targetWeightKg - startingWeightKg
    }

    var remainingWeightChangeKg: Double {
        targetWeightKg - currentWeightKg
    }

    var isGoalReached: Bool {
        switch goalType {
        case .fatLoss:
            return currentWeightKg <= targetWeightKg
        case .weightGain:
            return currentWeightKg >= targetWeightKg
        }
    }

    var currentWeekNumber: Int {
        max(1, Date().weeksFrom(startDate) + 1)
    }

    var projectedEndDate: Date {
        let remainingKg = abs(remainingWeightChangeKg)
        let weeksNeeded = selectedPaceKgPerWeek > 0 ? Int(ceil(remainingKg / selectedPaceKgPerWeek)) : 0
        return Date().adding(weeks: weeksNeeded)
    }
}
