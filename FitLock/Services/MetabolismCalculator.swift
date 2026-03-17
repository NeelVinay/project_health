import Foundation

enum MetabolismCalculator {

    // MARK: - BMR (Mifflin-St Jeor)

    static func calculateBMR(weightKg: Double, heightCm: Double, ageYears: Int, sex: BiologicalSex) -> Double {
        let base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(ageYears))
        switch sex {
        case .male:   return base + 5.0
        case .female: return base - 161.0
        }
    }

    static func calculateBMR(profile: UserProfile) -> Double {
        calculateBMR(
            weightKg: profile.currentWeightKg,
            heightCm: profile.heightCm,
            ageYears: profile.ageYears,
            sex: profile.biologicalSex
        )
    }

    // MARK: - Activity Multiplier (from average daily steps)

    static func estimateActivityMultiplier(averageSteps: Int) -> Double {
        switch averageSteps {
        case ..<5_000:       return 1.2    // Sedentary
        case 5_000..<7_500:  return 1.375  // Lightly active
        case 7_500..<10_000: return 1.55   // Moderately active
        case 10_000..<12_500: return 1.725 // Very active
        default:             return 1.9    // Extra active
        }
    }

    // MARK: - TDEE

    static func calculateTDEE(bmr: Double, activityMultiplier: Double) -> Double {
        bmr * activityMultiplier
    }

    static func calculateTDEE(profile: UserProfile, averageSteps: Int) -> Double {
        let bmr = calculateBMR(profile: profile)
        let multiplier = estimateActivityMultiplier(averageSteps: averageSteps)
        return calculateTDEE(bmr: bmr, activityMultiplier: multiplier)
    }

    // MARK: - Caloric Deficit / Surplus

    /// Daily deficit needed to lose `paceKgPerWeek` kg per week
    static func calculateDailyDeficit(paceKgPerWeek: Double) -> Double {
        let weeklyDeficit = paceKgPerWeek * AppConstants.Defaults.caloriesPerKgFat
        return weeklyDeficit / 7.0
    }

    /// Daily surplus needed to gain `paceKgPerWeek` kg per week
    static func calculateDailySurplus(paceKgPerWeek: Double) -> Double {
        let weeklySurplus = paceKgPerWeek * AppConstants.Defaults.caloriesPerKgFat
        return weeklySurplus / 7.0
    }

    /// Target daily calorie intake
    static func targetDailyIntake(tdee: Double, paceKgPerWeek: Double, goalType: GoalType) -> Double {
        switch goalType {
        case .fatLoss:
            return tdee - calculateDailyDeficit(paceKgPerWeek: paceKgPerWeek)
        case .weightGain:
            return tdee + calculateDailySurplus(paceKgPerWeek: paceKgPerWeek)
        }
    }

    // MARK: - Adaptation Factor

    /// Returns the metabolic adaptation factor for the given week number
    static func adaptationFactor(weekNumber: Int) -> Double {
        switch weekNumber {
        case 1...4:   return 1.00
        case 5...8:   return 0.95
        case 9...12:  return 0.90
        case 13...16: return 0.85
        case 17...20: return 0.80
        default:      return 0.75 // 21+ weeks — plateau zone
        }
    }

    /// Adjusted pace accounting for metabolic adaptation
    static func adjustedPace(originalPace: Double, weekNumber: Int) -> Double {
        originalPace * adaptationFactor(weekNumber: weekNumber)
    }

    // MARK: - Safety Checks (Advisory Only — Never Blocks User)

    /// Check if rate exceeds 1% of body weight per week
    static func isRateExceedingOnePercent(rateKgPerWeek: Double, currentWeightKg: Double) -> Bool {
        rateKgPerWeek > (currentWeightKg * 0.01)
    }

    /// Check if target intake would be below BMR
    static func isBelowBMR(targetIntake: Double, bmr: Double) -> Bool {
        targetIntake < bmr
    }

    /// Body fat category based on BMI proxy
    static func bodyFatCategory(bmi: Double, sex: BiologicalSex) -> BodyFatBracket {
        switch sex {
        case .male:
            if bmi > 30 { return .higher }      // > ~25% BF
            if bmi > 22 { return .moderate }     // 15-25% BF
            return .lower                         // < 15% BF
        case .female:
            if bmi > 33 { return .higher }       // > ~35% BF
            if bmi > 25 { return .moderate }     // 25-35% BF
            return .lower                         // < 25% BF
        }
    }

    enum BodyFatBracket: String {
        case higher   // Can sustain faster loss
        case moderate // Medium rates recommended
        case lower    // Slow rates recommended

        var paceRecommendation: String {
            switch self {
            case .higher:   return "Your body composition can support a faster pace if desired."
            case .moderate: return "A moderate pace is recommended for your body composition."
            case .lower:    return "A slower pace is recommended to preserve muscle mass."
            }
        }
    }

    // MARK: - Warning Generation (Advisory, Never Blocking)

    /// Generates a list of human-readable warning strings for the user's configuration.
    /// Empty array means no concerns.
    static func generateWarnings(profile: UserProfile, selectedPace: Double, averageSteps: Int = 7500) -> [HealthWarning] {
        var warnings: [HealthWarning] = []

        let bmr = calculateBMR(profile: profile)
        let tdee = calculateTDEE(profile: profile, averageSteps: averageSteps)
        let intake = targetDailyIntake(tdee: tdee, paceKgPerWeek: selectedPace, goalType: profile.goalType)

        // Check if rate exceeds 1% body weight
        if isRateExceedingOnePercent(rateKgPerWeek: selectedPace, currentWeightKg: profile.currentWeightKg) {
            warnings.append(HealthWarning(
                severity: .high,
                title: "Aggressive Rate",
                message: "Your selected rate of \(String(format: "%.2f", selectedPace)) kg/week exceeds 1% of your body weight per week. This may cause muscle loss, metabolic damage, or gallstones at extreme deficits."
            ))
        }

        // Check if intake would be below BMR
        if profile.goalType == .fatLoss && isBelowBMR(targetIntake: intake, bmr: bmr) {
            warnings.append(HealthWarning(
                severity: .high,
                title: "Intake Below BMR",
                message: "Your target daily intake of \(Int(intake)) kcal would be below your BMR of \(Int(bmr)) kcal. Eating below your BMR can slow your metabolism long-term and is counterproductive."
            ))
        }

        // Check body composition bracket vs pace
        let bracket = bodyFatCategory(bmi: profile.bmi, sex: profile.biologicalSex)
        if bracket == .lower && selectedPace > 0.25 {
            warnings.append(HealthWarning(
                severity: .medium,
                title: "Lean Body Composition",
                message: "At your current body composition, a fast rate of loss risks significant muscle loss. Consider slowing to 0.25 kg/week to preserve lean mass."
            ))
        }

        // Check if the timeframe is very short
        let requiredRate = abs(profile.targetWeightKg - profile.currentWeightKg) / Double(max(1, profile.targetTimeframeWeeks))
        if requiredRate > 1.0 && profile.goalType == .fatLoss {
            warnings.append(HealthWarning(
                severity: .medium,
                title: "Short Timeframe",
                message: "Your target timeframe requires losing \(String(format: "%.1f", requiredRate)) kg/week, which is considered aggressive. Consider extending your timeframe for healthier results."
            ))
        }

        return warnings
    }

    // MARK: - Pace Suggestion

    /// Suggests a pace and returns any warnings. User can ignore both.
    static func suggestPace(
        currentWeight: Double,
        targetWeight: Double,
        timeframeWeeks: Int,
        sex: BiologicalSex,
        heightCm: Double,
        ageYears: Int
    ) -> (pace: PacePreset, customRate: Double, warnings: [HealthWarning]) {
        let isLoss = targetWeight < currentWeight
        let goalType: GoalType = isLoss ? .fatLoss : .weightGain
        let totalChange = abs(targetWeight - currentWeight)
        let requiredRate = totalChange / Double(max(1, timeframeWeeks))

        // Find the closest pace preset
        let pace: PacePreset
        if requiredRate <= 0.375 {
            pace = .slow
        } else if requiredRate <= 0.75 {
            pace = .medium
        } else {
            pace = .fast
        }

        let profile = UserProfile(
            startingWeightKg: currentWeight,
            currentWeightKg: currentWeight,
            targetWeightKg: targetWeight,
            heightCm: heightCm,
            ageYears: ageYears,
            biologicalSex: sex,
            goalType: goalType,
            selectedPaceKgPerWeek: requiredRate,
            targetTimeframeWeeks: timeframeWeeks
        )
        let warnings = generateWarnings(profile: profile, selectedPace: requiredRate)

        return (pace, requiredRate, warnings)
    }

    // MARK: - Projected Completion Date

    static func projectedCompletionDate(
        from startDate: Date,
        currentWeight: Double,
        targetWeight: Double,
        paceKgPerWeek: Double
    ) -> Date {
        guard paceKgPerWeek > 0 else { return startDate }
        let remainingKg = abs(targetWeight - currentWeight)
        let weeksNeeded = Int(ceil(remainingKg / paceKgPerWeek))
        return startDate.adding(weeks: weeksNeeded)
    }

    // MARK: - Checkpoint Generation

    static func generateCheckpoint(
        weekNumber: Int,
        profile: UserProfile,
        averageSteps: Int
    ) -> AdaptationCheckpoint {
        let factor = adaptationFactor(weekNumber: weekNumber)
        let previousFactor = weekNumber > 4 ? adaptationFactor(weekNumber: weekNumber - 4) : 1.0

        let bmr = calculateBMR(profile: profile)
        let tdee = calculateTDEE(bmr: bmr, activityMultiplier: estimateActivityMultiplier(averageSteps: averageSteps))

        let adjustedPace = profile.selectedPaceKgPerWeek * factor
        let previousPace = profile.selectedPaceKgPerWeek * previousFactor

        let dailyTarget = targetDailyIntake(tdee: tdee, paceKgPerWeek: adjustedPace, goalType: profile.goalType)
        let previousDailyTarget = targetDailyIntake(tdee: tdee, paceKgPerWeek: previousPace, goalType: profile.goalType)

        let completionDate = projectedCompletionDate(
            from: Date(),
            currentWeight: profile.currentWeightKg,
            targetWeight: profile.targetWeightKg,
            paceKgPerWeek: adjustedPace
        )

        return AdaptationCheckpoint(
            weekNumber: weekNumber,
            currentWeightKg: profile.currentWeightKg,
            recalculatedBMR: bmr,
            recalculatedTDEE: tdee,
            adaptationFactor: factor,
            adjustedPaceKgPerWeek: adjustedPace,
            previousPaceKgPerWeek: previousPace,
            newProjectedCompletionDate: completionDate,
            dailyCalorieTarget: dailyTarget,
            previousDailyCalorieTarget: previousDailyTarget
        )
    }
}

// MARK: - Health Warning

struct HealthWarning: Identifiable, Equatable {
    let id = UUID()
    let severity: Severity
    let title: String
    let message: String

    enum Severity: String {
        case low, medium, high

        var colorName: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}
