import Foundation

enum UnitConverter {
    // MARK: - Weight
    static let kgPerLb: Double = 0.453592
    static let lbsPerKg: Double = 2.20462

    static func kgToLbs(_ kg: Double) -> Double {
        kg * lbsPerKg
    }

    static func lbsToKg(_ lbs: Double) -> Double {
        lbs * kgPerLb
    }

    static func weightString(_ kg: Double, useMetric: Bool, decimals: Int = 1) -> String {
        if useMetric {
            return String(format: "%.\(decimals)f kg", kg)
        } else {
            return String(format: "%.\(decimals)f lbs", kgToLbs(kg))
        }
    }

    static func weightValue(_ kg: Double, useMetric: Bool) -> Double {
        useMetric ? kg : kgToLbs(kg)
    }

    static func toKg(_ value: Double, useMetric: Bool) -> Double {
        useMetric ? value : lbsToKg(value)
    }

    // MARK: - Height
    static let cmPerInch: Double = 2.54
    static let cmPerFoot: Double = 30.48

    static func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / cmPerInch
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches.rounded()) % 12
        return (feet, inches)
    }

    static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) * cmPerInch
    }

    static func heightString(_ cm: Double, useMetric: Bool) -> String {
        if useMetric {
            return String(format: "%.0f cm", cm)
        } else {
            let (feet, inches) = cmToFeetInches(cm)
            return "\(feet)'\(inches)\""
        }
    }

    // MARK: - Calorie formatting
    static func calorieString(_ kcal: Double) -> String {
        if kcal >= 1000 {
            return String(format: "%.0f kcal", kcal)
        } else {
            return String(format: "%.0f kcal", kcal)
        }
    }

    // MARK: - Step formatting
    static func stepString(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}
