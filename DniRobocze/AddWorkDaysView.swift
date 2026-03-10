import SwiftUI

struct AddWorkDaysView: View {
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var days: Int = 5
    @State private var daysText: String = "5"
    @State private var result: String? = nil
    @State private var isError = false
    @FocusState private var daysFieldFocused: Bool

    private static let resultFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

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
                            TextField("0", text: $daysText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($daysFieldFocused)
                                .frame(width: 70)
                                .foregroundStyle(days < 0 ? .orange : .primary)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .onChange(of: daysText) { _, newValue in handleDaysInput(newValue) }
                        }
                    }
                    .onChange(of: days) { _, newValue in
                        if !daysFieldFocused {
                            daysText = "\(newValue)"
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

    private func handleDaysInput(_ newValue: String) {
        if newValue.isEmpty { return }
        // numberPad only produces digits; strip anything else
        let digits = newValue.filter { $0.isNumber }
        if digits != newValue {
            daysText = digits
            return
        }
        if let parsed = Int(newValue) {
            days = min(max(parsed, -999), 999)
        }
    }

    private func calculate() {
        daysFieldFocused = false

        // Parse whatever is in the text field
        if let parsed = Int(daysText) {
            days = min(max(parsed, -999), 999)
        }
        daysText = "\(days)"

        let cal = WorkDaysEngine.calendar
        let s = cal.startOfDay(for: startDate)
        let resultDate = WorkDaysEngine.addWorkdays(days, to: s)

        let dateString = AddWorkDaysView.resultFormatter.string(from: resultDate)

        let weekdayIndex = cal.component(.weekday, from: resultDate) - 1
        let names = WorkDaysEngine.polishWeekdayNames
        let dayName = names.indices.contains(weekdayIndex) ? names[weekdayIndex] : ""

        isError = false
        result = "\(dateString)\n(\(dayName))"
    }
}

#Preview {
    AddWorkDaysView()
}
