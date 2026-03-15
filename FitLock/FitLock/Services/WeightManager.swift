import Foundation
import Observation

@Observable
final class WeightManager {
    private let storage: GoalStorage

    var weeklyRecords: [WeeklyWeightRecord] = []

    init(storage: GoalStorage) {
        self.storage = storage
        self.weeklyRecords = storage.loadWeeklyRecords()
    }

    // MARK: - Add Weight Entry

    func addWeightEntry(weightKg: Double, source: WeightSource, date: Date = Date()) {
        guard let profile = storage.loadProfile() else { return }

        let entry = DailyWeight(date: date, weightKg: weightKg, source: source)
        let weekNumber = weekNumberFor(date: date, startDate: profile.startDate)

        // Find or create the weekly record
        if let index = weeklyRecords.firstIndex(where: { $0.weekNumber == weekNumber }) {
            weeklyRecords[index].dailyWeights.append(entry)
            weeklyRecords[index].recalculateAverage()
        } else {
            let weekStart = profile.startDate.adding(weeks: weekNumber - 1)
            let weekEnd = weekStart.adding(days: 6)
            var record = WeeklyWeightRecord(
                weekNumber: weekNumber,
                startDate: weekStart,
                endDate: weekEnd,
                dailyWeights: [entry],
                averageWeightKg: weightKg,
                expectedChangeKg: expectedChange(forWeek: weekNumber, profile: profile)
            )
            record.recalculateAverage()
            weeklyRecords.append(record)
            weeklyRecords.sort { $0.weekNumber < $1.weekNumber }
        }

        // Recalculate comparisons
        recalculateAllComparisons(profile: profile)

        // Update current weight on profile
        var updatedProfile = profile
        updatedProfile.currentWeightKg = weightKg
        storage.saveProfile(updatedProfile)

        // Persist
        storage.saveWeeklyRecords(weeklyRecords)
    }

    // MARK: - Week Number Calculation

    func weekNumberFor(date: Date, startDate: Date) -> Int {
        let daysSinceStart = date.daysFrom(startDate)
        return max(1, (daysSinceStart / 7) + 1)
    }

    // MARK: - Expected Change

    func expectedChange(forWeek weekNumber: Int, profile: UserProfile) -> Double {
        let factor = MetabolismCalculator.adaptationFactor(weekNumber: weekNumber)
        let adjustedPace = profile.selectedPaceKgPerWeek * factor
        switch profile.goalType {
        case .fatLoss: return -adjustedPace
        case .weightGain: return adjustedPace
        }
    }

    // MARK: - Weekly Comparison

    func compareWeeks(
        current: WeeklyWeightRecord,
        previous: WeeklyWeightRecord,
        goalType: GoalType
    ) -> (onTrack: Bool, actualChange: Double, expectedChange: Double) {
        let actualChange = current.averageWeightKg - previous.averageWeightKg
        let expectedChange = current.expectedChangeKg
        let tolerance = AppConstants.Defaults.waterWeightTolerance

        let onTrack: Bool
        switch goalType {
        case .fatLoss:
            // expectedChange is negative (e.g., -0.5)
            // on track if actual change <= expected + tolerance
            onTrack = actualChange <= (expectedChange + tolerance)
        case .weightGain:
            // expectedChange is positive (e.g., +0.5)
            // on track if actual change >= expected - tolerance
            onTrack = actualChange >= (expectedChange - tolerance)
        }

        return (onTrack, actualChange, expectedChange)
    }

    // MARK: - Recalculate All Comparisons

    private func recalculateAllComparisons(profile: UserProfile) {
        for i in 0..<weeklyRecords.count {
            let weekNum = weeklyRecords[i].weekNumber
            weeklyRecords[i].expectedChangeKg = expectedChange(forWeek: weekNum, profile: profile)

            if weekNum <= AppConstants.Defaults.baselineWeeks {
                weeklyRecords[i].actualChangeKg = nil
                weeklyRecords[i].onTrack = nil
            } else if let prevIndex = weeklyRecords.firstIndex(where: { $0.weekNumber == weekNum - 1 }),
                      weeklyRecords[prevIndex].hasEntries {
                let result = compareWeeks(
                    current: weeklyRecords[i],
                    previous: weeklyRecords[prevIndex],
                    goalType: profile.goalType
                )
                weeklyRecords[i].actualChangeKg = result.actualChange
                weeklyRecords[i].onTrack = result.onTrack
            }
        }
    }

    // MARK: - Should Lock for Weight

    /// Returns true if the last 2 consecutive weeks are off track
    func shouldLockForWeight() -> Bool {
        let completedRecords = weeklyRecords
            .filter { $0.onTrack != nil && $0.hasEntries }
            .sorted { $0.weekNumber < $1.weekNumber }

        guard completedRecords.count >= 2 else { return false }

        let lastTwo = completedRecords.suffix(2)
        return lastTwo.allSatisfy { $0.onTrack == false }
    }

    // MARK: - Get Current Week Entries

    func getCurrentWeekEntries() -> [DailyWeight] {
        guard let profile = storage.loadProfile() else { return [] }
        let currentWeek = weekNumberFor(date: Date(), startDate: profile.startDate)
        return weeklyRecords.first(where: { $0.weekNumber == currentWeek })?.dailyWeights ?? []
    }

    // MARK: - Get Latest Weekly Average

    func latestWeeklyAverage() -> Double? {
        weeklyRecords
            .filter { $0.hasEntries }
            .sorted { $0.weekNumber > $1.weekNumber }
            .first?
            .averageWeightKg
    }

    // MARK: - Projection Data for Chart

    func generateProjectionData(profile: UserProfile) -> [WeightProjectionPoint] {
        var points: [WeightProjectionPoint] = []

        let totalWeeksNeeded: Int
        let remainingKg = abs(profile.targetWeightKg - profile.currentWeightKg)
        if profile.selectedPaceKgPerWeek > 0 {
            totalWeeksNeeded = max(profile.targetTimeframeWeeks, Int(ceil(remainingKg / profile.selectedPaceKgPerWeek)) + 4)
        } else {
            totalWeeksNeeded = profile.targetTimeframeWeeks
        }

        var expectedWeight = profile.startingWeightKg

        for week in 1...totalWeeksNeeded {
            let factor = MetabolismCalculator.adaptationFactor(weekNumber: week)
            let weeklyChange = profile.selectedPaceKgPerWeek * factor

            switch profile.goalType {
            case .fatLoss:
                expectedWeight -= weeklyChange
                expectedWeight = max(expectedWeight, profile.targetWeightKg)
            case .weightGain:
                expectedWeight += weeklyChange
                expectedWeight = min(expectedWeight, profile.targetWeightKg)
            }

            let actualWeight = weeklyRecords
                .first(where: { $0.weekNumber == week && $0.hasEntries })?
                .averageWeightKg

            let isCheckpoint = week % AppConstants.Defaults.checkpointIntervalWeeks == 0
            let weekDate = profile.startDate.adding(weeks: week - 1)

            points.append(WeightProjectionPoint(
                weekNumber: week,
                expectedWeightKg: expectedWeight,
                actualWeightKg: actualWeight,
                isCheckpoint: isCheckpoint,
                date: weekDate
            ))
        }

        return points
    }

    // MARK: - Check if Checkpoint is Due

    func isCheckpointDue(profile: UserProfile) -> Bool {
        let currentWeek = weekNumberFor(date: Date(), startDate: profile.startDate)
        let interval = AppConstants.Defaults.checkpointIntervalWeeks
        guard currentWeek >= interval && currentWeek % interval == 0 else { return false }

        let existingCheckpoints = storage.loadCheckpoints()
        return !existingCheckpoints.contains(where: { $0.weekNumber == currentWeek })
    }

    // MARK: - Reload

    func reload() {
        weeklyRecords = storage.loadWeeklyRecords()
        if let profile = storage.loadProfile() {
            recalculateAllComparisons(profile: profile)
        }
    }
}
