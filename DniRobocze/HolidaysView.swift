import SwiftUI

struct HolidaysView: View {
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private let currentYear = Calendar.current.component(.year, from: Date())
    var holidays: [(date: Date, name: String)] {
        WorkDaysEngine.namedHolidays(for: selectedYear)
    }

    var body: some View {
        NavigationStack {
            List(holidays, id: \.date) { holiday in
                HolidayRow(holiday: holiday)
            }
            .navigationTitle("Święta \(selectedYear)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach((currentYear - 5)...(currentYear + 10), id: \.self) { year in
                            Button("\(year)") {
                                selectedYear = year
                            }
                        }
                    } label: {
                        Label("Rok: \(selectedYear)", systemImage: "calendar")
                    }
                }
            }
        }
    }
}

struct HolidayRow: View {
    let holiday: (date: Date, name: String)

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var weekdayName: String {
        let idx = WorkDaysEngine.calendar.component(.weekday, from: holiday.date) - 1
        let names = WorkDaysEngine.polishWeekdayNames
        return names.indices.contains(idx) ? names[idx] : ""
    }

    private var isWeekend: Bool {
        let wd = WorkDaysEngine.calendar.component(.weekday, from: holiday.date)
        return wd == 1 || wd == 7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(holiday.name)
                .font(.body)
                .fontWeight(.medium)
            HStack(spacing: 6) {
                Text(HolidayRow.dateFormatter.string(from: holiday.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(weekdayName)
                    .font(.caption)
                    .foregroundStyle(isWeekend ? .orange : .secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HolidaysView()
}
