import SwiftUI

struct CountWorkDaysView: View {
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var result: String? = nil
    @State private var resultCount: Int? = nil
    @State private var isError = false
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Zakres dat") {
                    DatePicker("Od", selection: $startDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pl_PL"))
                    DatePicker("Do", selection: $endDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pl_PL"))
                }

                Section {
                    Button(action: calculate) {
                        HStack {
                            Spacer()
                            Label("Oblicz", systemImage: "equal.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
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
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(isError ? Color.red : Color.green)
                                .multilineTextAlignment(.center)
                            Spacer()
                            if !isError, let count = resultCount {
                                Button {
                                    UIPasteboard.general.string = "\(count)"
                                    copied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        copied = false
                                    }
                                } label: {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                        .foregroundStyle(copied ? .green : .secondary)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Policz dni robocze")
        }
    }

    private func calculate() {
        let cal = WorkDaysEngine.calendar
        let s = cal.startOfDay(for: startDate)
        let e = cal.startOfDay(for: endDate)

        guard s <= e else {
            result = "Data \"Od\" musi być\nwcześniejsza lub równa \"Do\""
            isError = true
            return
        }

        let count = WorkDaysEngine.countWorkdays(from: s, to: e)
        isError = false
        resultCount = count
        result = "\(count) \(workdayLabel(count))"
    }

    private func workdayLabel(_ n: Int) -> String {
        // Polish grammatical agreement rules for cardinal numbers:
        //   1                     → "dzień roboczy"
        //   ends in 12, 13, 14   → "dni roboczych"  (teen override)
        //   ends in 2, 3, 4      → "dni robocze"
        //   everything else      → "dni roboczych"
        if n == 1 { return "dzień roboczy" }
        let mod100 = n % 100
        if (12...14).contains(mod100) { return "dni roboczych" }
        let mod10 = n % 10
        if (2...4).contains(mod10) { return "dni robocze" }
        return "dni roboczych"
    }
}

#Preview {
    CountWorkDaysView()
}
