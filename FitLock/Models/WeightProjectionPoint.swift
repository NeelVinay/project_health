import Foundation

struct WeightProjectionPoint: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var weekNumber: Int
    var expectedWeightKg: Double            // projected from pace + adaptation
    var actualWeightKg: Double?             // nil for future weeks
    var isCheckpoint: Bool                  // true at 4-week marks
    var date: Date                          // the date this week starts

    var hasActualData: Bool {
        actualWeightKg != nil
    }

    var differenceKg: Double? {
        guard let actual = actualWeightKg else { return nil }
        return actual - expectedWeightKg
    }
}
