import Foundation

public enum BNCalendar {
    public static let timeZone = TimeZone(identifier: "Asia/Shanghai")!

    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }()

    public static func date(from dateKey: String) -> Date? {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone

        let parts = dateKey.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }

        components.year = year
        components.month = month
        components.day = day
        return calendar.startOfDay(for: calendar.date(from: components)!)
    }

    public static func dateKey(from date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    public static func days(from startDate: Date, to endDate: Date) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
