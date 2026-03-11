import Foundation

// MARK: - Shift Type

enum DyzurType: String, Codable, CaseIterable {
    case weekday = "weekday"
    case weekend = "weekend"

    var localizedName: String {
        switch self {
        case .weekday: return "Dyżur"
        case .weekend: return "Dyżur weekendowy"
        }
    }

    /// Duration in seconds: weekday = 16 h 25 min, weekend = 24 h.
    var duration: TimeInterval {
        switch self {
        case .weekday: return (16 * 60 + 25) * 60
        case .weekend: return 24 * 60 * 60
        }
    }

    var durationDescription: String {
        switch self {
        case .weekday: return "16 godz. 25 min."
        case .weekend: return "24 godz."
        }
    }
}

// MARK: - Shift Model

struct Dyzur: Identifiable, Codable {
    var id: UUID
    var date: Date
    var type: DyzurType

    init(id: UUID = UUID(), date: Date, type: DyzurType) {
        self.id = id
        self.date = date
        self.type = type
    }

    var duration: TimeInterval { type.duration }

    // MARK: - Calendar helpers

    /// Returns the start date of the shift for calendar purposes.
    /// - Note: For `.weekday` the shift starts at 15:00 of `date`.
    ///         For `.weekend` the shift starts at 07:25 of `date`.
    var startDate: Date {
        let cal = WorkDaysEngine.calendar
        var components = cal.dateComponents([.year, .month, .day], from: date)
        switch type {
        case .weekday:
            components.hour = 15
            components.minute = 0
        case .weekend:
            components.hour = 7
            components.minute = 25
        }
        return cal.date(from: components) ?? date
    }

    /// Returns the end date of the shift for calendar purposes.
    /// Both shift types end the next day at 07:25.
    var endDate: Date {
        let cal = WorkDaysEngine.calendar
        let nextDay = cal.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        var components = cal.dateComponents([.year, .month, .day], from: nextDay)
        components.hour = 7
        components.minute = 25
        return cal.date(from: components) ?? nextDay
    }
}

// MARK: - Store

@Observable
final class DyzuryStore {
    var dyzury: [Dyzur] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("dyzury.json")
    }()

    init() { load() }

    // MARK: CRUD

    func add(_ dyzur: Dyzur) {
        dyzury.append(dyzur)
        dyzury.sort { $0.date < $1.date }
        save()
    }

    func update(_ dyzur: Dyzur) {
        guard let idx = dyzury.firstIndex(where: { $0.id == dyzur.id }) else { return }
        dyzury[idx] = dyzur
        dyzury.sort { $0.date < $1.date }
        save()
    }

    func remove(at offsets: IndexSet) {
        dyzury.remove(atOffsets: offsets)
        save()
    }

    func remove(id: UUID) {
        dyzury.removeAll { $0.id == id }
        save()
    }

    // MARK: Totals

    /// Total hours worked (optionally filtered by date range).
    func totalHours(from start: Date = .distantPast, to end: Date = .distantFuture) -> Double {
        dyzury
            .filter { $0.date >= start && $0.date <= end }
            .reduce(0) { $0 + $1.duration } / 3600.0
    }

    var totalWeekdayShifts: Int { dyzury.filter { $0.type == .weekday }.count }
    var totalWeekendShifts: Int { dyzury.filter { $0.type == .weekend }.count }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode([Dyzur].self, from: data) {
            dyzury = loaded.sorted { $0.date < $1.date }
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(dyzury) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: CSV Export

    func csvString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "yyyy-MM-dd"

        var lines = ["Data,Typ dyżuru,Czas trwania (min)"]
        for d in dyzury {
            let date = formatter.string(from: d.date)
            let type = d.type.localizedName
            let mins = Int(d.duration / 60)
            lines.append("\(date),\(type),\(mins)")
        }
        return lines.joined(separator: "\n")
    }
}

