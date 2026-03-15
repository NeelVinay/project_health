import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }

    func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: self)!
    }

    func weeksAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -n, to: self)!
    }

    func daysFrom(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date.startOfDay, to: self.startOfDay).day ?? 0
    }

    func weeksFrom(_ date: Date) -> Int {
        Calendar.current.dateComponents([.weekOfYear], from: date.startOfDay, to: self.startOfDay).weekOfYear ?? 0
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: self)
    }

    /// Returns a Date set to the given hour and minute on this date's day
    func atTime(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self)!
    }

    /// Whether the current time is past the given hour:minute today
    static func isPastTime(hour: Int, minute: Int) -> Bool {
        let now = Date()
        let checkTime = now.atTime(hour: hour, minute: minute)
        return now >= checkTime
    }

    /// Format as short date string
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format as week range string (e.g., "Mar 1 - Mar 7")
    func weekRangeString(weekLength: Int = 7) -> String {
        let end = adding(days: weekLength - 1)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: self)) - \(formatter.string(from: end))"
    }
}
