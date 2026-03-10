import Foundation

// MARK: - Polish Work Days Engine

struct WorkDaysEngine {

    // Shared Gregorian calendar – avoids creating a new instance on every call.
    static let calendar = Calendar(identifier: .gregorian)

    /// Polish weekday names indexed by `Calendar.weekday - 1` (0 = Sunday … 6 = Saturday).
    static let polishWeekdayNames = [
        "niedziela", "poniedziałek", "wtorek", "środa", "czwartek", "piątek", "sobota"
    ]

    // MARK: Easter (Meeus/Jones/Butcher algorithm)

    static func easter(year: Int) -> DateComponents {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return DateComponents(year: year, month: month, day: day)
    }

    // MARK: Holiday generation

    static func holidays(for year: Int) -> Set<Date> {
        var dates = Set<Date>()
        let cal = calendar

        func makeDate(_ month: Int, _ day: Int) -> Date? {
            cal.date(from: DateComponents(year: year, month: month, day: day))
                .map { cal.startOfDay(for: $0) }
        }

        // Fixed holidays
        let fixed = [
            makeDate(1, 1),  makeDate(1, 6),  makeDate(5, 1),  makeDate(5, 3),
            makeDate(8, 15), makeDate(11, 1), makeDate(11, 11),
            makeDate(12, 25), makeDate(12, 26)
        ]
        fixed.compactMap { $0 }.forEach { dates.insert($0) }

        // Wigilia from 2025 onward
        if year >= 2025, let wigilia = makeDate(12, 24) {
            dates.insert(wigilia)
        }

        // Moveable: Easter-based
        if let easterDate = cal.date(from: easter(year: year)).map({ cal.startOfDay(for: $0) }) {
            dates.insert(easterDate)                         // Wielkanoc
            dates.insert(easterDate.addingDays(1))           // Poniedziałek Wielkanocny
            dates.insert(easterDate.addingDays(49))          // Zielone Świątki
            dates.insert(easterDate.addingDays(60))          // Boże Ciało
        }

        return dates
    }

    static func namedHolidays(for year: Int) -> [(date: Date, name: String)] {
        let cal = calendar

        func makeDate(_ month: Int, _ day: Int) -> Date? {
            cal.date(from: DateComponents(year: year, month: month, day: day))
                .map { cal.startOfDay(for: $0) }
        }

        let fixed: [(Int, Int, String)] = [
            (1,  1,  "Nowy Rok"),
            (1,  6,  "Święto Trzech Króli"),
            (5,  1,  "Święto Pracy"),
            (5,  3,  "Święto Konstytucji 3 Maja"),
            (8,  15, "Wniebowzięcie Najświętszej Maryi Panny"),
            (11, 1,  "Wszystkich Świętych"),
            (11, 11, "Narodowe Święto Niepodległości"),
            (12, 25, "Boże Narodzenie (1. dzień)"),
            (12, 26, "Boże Narodzenie (2. dzień)"),
        ]

        var list: [(Date, String)] = fixed.compactMap { m, d, name in
            makeDate(m, d).map { ($0, name) }
        }

        if year >= 2025, let wigilia = makeDate(12, 24) {
            list.append((wigilia, "Wigilia Bożego Narodzenia"))
        }

        if let easterDate = cal.date(from: easter(year: year)).map({ cal.startOfDay(for: $0) }) {
            list.append((easterDate, "Wielkanoc"))
            list.append((easterDate.addingDays(1), "Poniedziałek Wielkanocny"))
            list.append((easterDate.addingDays(49), "Zielone Świątki"))
            list.append((easterDate.addingDays(60), "Boże Ciało"))
        }

        return list.sorted { $0.0 < $1.0 }
    }

    // MARK: Work day checks

    static func isWorkday(_ date: Date, holidayCache: inout [Int: Set<Date>]) -> Bool {
        let cal = calendar
        let weekday = cal.component(.weekday, from: date) // 1=Sun, 7=Sat
        guard weekday != 1 && weekday != 7 else { return false }
        let year = cal.component(.year, from: date)
        if holidayCache[year] == nil {
            holidayCache[year] = holidays(for: year)
        }
        return !(holidayCache[year]?.contains(cal.startOfDay(for: date)) ?? false)
    }

    // MARK: Count work days between two dates (inclusive)

    static func countWorkdays(from start: Date, to end: Date) -> Int {
        let cal = calendar
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        guard s <= e else { return 0 }

        var cache: [Int: Set<Date>] = [:]
        var count = 0
        var current = s
        while current <= e {
            if isWorkday(current, holidayCache: &cache) { count += 1 }
            current = current.addingDays(1)
        }
        return count
    }

    // MARK: Add N work days to a date (exclusive start)

    static func addWorkdays(_ n: Int, to date: Date) -> Date {
        guard n != 0 else { return date }
        let cal = calendar
        var cache: [Int: Set<Date>] = [:]
        var current = cal.startOfDay(for: date)
        let step = n > 0 ? 1 : -1
        var remaining = abs(n)
        while remaining > 0 {
            current = current.addingDays(step)
            if isWorkday(current, holidayCache: &cache) {
                remaining -= 1
            }
        }
        return current
    }
}

// MARK: - Date helpers

extension Date {
    func addingDays(_ days: Int) -> Date {
        WorkDaysEngine.calendar.date(byAdding: .day, value: days, to: self) ?? self
    }
}
