import Foundation

// MARK: - Polish Work Days Engine

struct WorkDaysEngine {

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
        let cal = Calendar(identifier: .gregorian)

        func date(_ month: Int, _ day: Int) -> Date {
            var dc = DateComponents()
            dc.year = year
            dc.month = month
            dc.day = day
            return cal.startOfDay(for: cal.date(from: dc)!)
        }

        // Fixed holidays
        dates.insert(date(1, 1))   // Nowy Rok
        dates.insert(date(1, 6))   // Trzech Króli
        dates.insert(date(5, 1))   // Święto Pracy
        dates.insert(date(5, 3))   // Święto Konstytucji
        dates.insert(date(8, 15))  // Wniebowzięcie NMP
        dates.insert(date(11, 1))  // Wszystkich Świętych
        dates.insert(date(11, 11)) // Święto Niepodległości
        dates.insert(date(12, 25)) // Boże Narodzenie (1)
        dates.insert(date(12, 26)) // Boże Narodzenie (2)

        // Wigilia from 2025 onward
        if year >= 2025 {
            dates.insert(date(12, 24))
        }

        // Moveable: Easter-based
        let easterDC = easter(year: year)
        let easterDate = cal.startOfDay(for: cal.date(from: easterDC)!)
        dates.insert(easterDate)                                          // Wielkanoc
        dates.insert(easterDate.addingDays(1))                           // Poniedziałek Wielkanocny
        dates.insert(easterDate.addingDays(49))                          // Zielone Świątki
        dates.insert(easterDate.addingDays(60))                          // Boże Ciało

        return dates
    }

    static func namedHolidays(for year: Int) -> [(date: Date, name: String)] {
        let cal = Calendar(identifier: .gregorian)

        func date(_ month: Int, _ day: Int) -> Date {
            var dc = DateComponents()
            dc.year = year; dc.month = month; dc.day = day
            return cal.startOfDay(for: cal.date(from: dc)!)
        }

        var list: [(Date, String)] = [
            (date(1, 1),   "Nowy Rok"),
            (date(1, 6),   "Święto Trzech Króli"),
            (date(5, 1),   "Święto Pracy"),
            (date(5, 3),   "Święto Konstytucji 3 Maja"),
            (date(8, 15),  "Wniebowzięcie Najświętszej Maryi Panny"),
            (date(11, 1),  "Wszystkich Świętych"),
            (date(11, 11), "Narodowe Święto Niepodległości"),
            (date(12, 25), "Boże Narodzenie (1. dzień)"),
            (date(12, 26), "Boże Narodzenie (2. dzień)"),
        ]

        if year >= 2025 {
            list.append((date(12, 24), "Wigilia Bożego Narodzenia"))
        }

        let easterDC = easter(year: year)
        let easterDate = cal.startOfDay(for: cal.date(from: easterDC)!)
        list.append((easterDate, "Wielkanoc"))
        list.append((easterDate.addingDays(1), "Poniedziałek Wielkanocny"))
        list.append((easterDate.addingDays(49), "Zielone Świątki"))
        list.append((easterDate.addingDays(60), "Boże Ciało"))

        return list.sorted { $0.0 < $1.0 }
    }

    // MARK: Work day checks

    static func isWorkday(_ date: Date, holidayCache: inout [Int: Set<Date>]) -> Bool {
        let cal = Calendar(identifier: .gregorian)
        let weekday = cal.component(.weekday, from: date) // 1=Sun, 7=Sat
        guard weekday != 1 && weekday != 7 else { return false }
        let year = cal.component(.year, from: date)
        if holidayCache[year] == nil {
            holidayCache[year] = holidays(for: year)
        }
        return !holidayCache[year]!.contains(cal.startOfDay(for: date))
    }

    // MARK: Count work days between two dates (inclusive)

    static func countWorkdays(from start: Date, to end: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
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
        let cal = Calendar(identifier: .gregorian)
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
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}
