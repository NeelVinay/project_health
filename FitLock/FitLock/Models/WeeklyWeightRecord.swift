import Foundation

// MARK: - Weight Source

enum WeightSource: String, Codable {
    case manual
    case healthKit
}

// MARK: - Daily Weight Entry

struct DailyWeight: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double
    var source: WeightSource
}

// MARK: - Weekly Weight Record

struct WeeklyWeightRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var weekNumber: Int                     // 1, 2, 3, ...
    var startDate: Date
    var endDate: Date
    var dailyWeights: [DailyWeight]         // individual entries during the week
    var averageWeightKg: Double             // calculated
    var expectedChangeKg: Double            // what adaptation model predicted
    var actualChangeKg: Double?             // vs previous week (nil for week 1)
    var onTrack: Bool?                      // nil for weeks 1-2

    var hasEntries: Bool {
        !dailyWeights.isEmpty
    }

    var entryCount: Int {
        dailyWeights.count
    }

    var dateRangeString: String {
        startDate.weekRangeString()
    }

    /// Recalculate average from daily weights
    mutating func recalculateAverage() {
        guard !dailyWeights.isEmpty else { return }
        averageWeightKg = dailyWeights.map(\.weightKg).reduce(0, +) / Double(dailyWeights.count)
    }
}
