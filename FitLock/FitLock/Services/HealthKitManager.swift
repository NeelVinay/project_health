import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    private let healthStore = HKHealthStore()

    var isAuthorized = false
    var todaySteps: Int = 0
    var todayCalories: Double = 0.0
    var authorizationError: String?

    private var observerQueries: [HKObserverQuery] = []

    // MARK: - Types

    private let stepType = HKQuantityType(.stepCount)
    private let calorieType = HKQuantityType(.activeEnergyBurned)
    private let weightType = HKQuantityType(.bodyMass)

    private var readTypes: Set<HKObjectType> {
        [stepType, calorieType, weightType]
    }

    // MARK: - Authorization

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit is not available on this device."
            return
        }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
        authorizationError = nil
    }

    // MARK: - Fetch Today's Steps

    func fetchTodaySteps() async throws -> Int {
        let now = Date()
        let startOfDay = now.startOfDay
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(sum))
            }
            healthStore.execute(query)
        }

        todaySteps = steps
        return steps
    }

    // MARK: - Fetch Today's Active Calories

    func fetchTodayCalories() async throws -> Double {
        let now = Date()
        let startOfDay = now.startOfDay
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let calories = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sum = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }

        todayCalories = calories
        return calories
    }

    // MARK: - Fetch Weight from HealthKit

    func fetchRecentWeight(days: Int = 30) async throws -> [DailyWeight] {
        let startDate = Date().daysAgo(days)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }
            healthStore.execute(query)
        }

        return samples.map { sample in
            DailyWeight(
                date: sample.startDate,
                weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                source: .healthKit
            )
        }
    }

    // MARK: - Fetch Average Steps (for activity multiplier estimation)

    func fetchAverageSteps(days: Int = 7) async throws -> Int {
        let startDate = Date().daysAgo(days)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let avgSteps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let totalSteps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                let avgDaily = Int(totalSteps / Double(days))
                continuation.resume(returning: avgDaily)
            }
            healthStore.execute(query)
        }

        return avgSteps
    }

    // MARK: - Observer Queries for Background Updates

    func setupObserverQueries(onUpdate: @escaping () -> Void) {
        let types: [HKQuantityType] = [stepType, calorieType]

        for type in types {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                guard self != nil, error == nil else {
                    completionHandler()
                    return
                }
                onUpdate()
                completionHandler()
            }
            healthStore.execute(query)
            observerQueries.append(query)
        }
    }

    func enableBackgroundDelivery() async {
        let types: [HKQuantityType] = [stepType, calorieType]

        for type in types {
            do {
                try await healthStore.enableBackgroundDelivery(for: type, frequency: .hourly)
            } catch {
                print("Failed to enable background delivery for \(type): \(error)")
            }
        }
    }

    // MARK: - Refresh All

    func refreshAll() async {
        do {
            _ = try await fetchTodaySteps()
            _ = try await fetchTodayCalories()
        } catch {
            print("Error refreshing HealthKit data: \(error)")
        }
    }

    // MARK: - Cleanup

    func stopObserverQueries() {
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
    }
}
