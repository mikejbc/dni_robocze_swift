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
        switch n {
        case 1:        return "dzień roboczy"
        case 2...4:    return "dni robocze"
        case 12...14:  return "dni roboczych"
        default:
            let mod = n % 10
            if (2...4).contains(mod) { return "dni robocze" }
            return "dni roboczych"
        }
    }
}

#Preview {
    CountWorkDaysView()
}
