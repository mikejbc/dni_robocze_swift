import SwiftUI

struct AddWorkDaysView: View {
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var days: Int = 5
    @State private var result: String? = nil
    @State private var isError = false

    private let polishDayNames = ["niedziela", "poniedziałek", "wtorek", "środa", "czwartek", "piątek", "sobota"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Data początkowa") {
                    DatePicker("Data", selection: $startDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pl_PL"))
                }

                Section("Liczba dni roboczych") {
                    Stepper(value: $days, in: -999...999) {
                        HStack {
                            Text("Dni:")
                            Spacer()
                            Text("\(days)")
                                .foregroundStyle(days < 0 ? .orange : .primary)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                    Text("Ujemna wartość odejmuje dni.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(action: calculate) {
                        Label("Oblicz", systemImage: "equal.circle.fill")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
                }

                if let result {
                    Section("Wynik") {
                        HStack {
                            Spacer()
                            Text(result)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(isError ? Color.red : Color.green)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Dodaj dni robocze")
        }
    }

    private func calculate() {
        let s = Calendar(identifier: .gregorian).startOfDay(for: startDate)
        let resultDate = WorkDaysEngine.addWorkdays(days, to: s)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: resultDate)

        let weekdayIndex = Calendar(identifier: .gregorian).component(.weekday, from: resultDate) - 1
        let dayName = polishDayNames[weekdayIndex]

        isError = false
        result = "\(dateString)\n(\(dayName))"
    }
}

#Preview {
    AddWorkDaysView()
}
