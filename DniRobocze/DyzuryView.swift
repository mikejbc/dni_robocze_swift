import SwiftUI

struct DyzuryView: View {
    @State private var store = DyzuryStore()
    @State private var showingAddSheet = false
    @State private var editingDyzur: Dyzur?
    @State private var showingExport = false
    @State private var csvContent = ""

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                summarySection
                shiftsSection
            }
            .navigationTitle("Dyżury")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        csvContent = store.csvString()
                        showingExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(store.dyzury.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                DyzurFormView(store: store)
            }
            .sheet(item: $editingDyzur) { dyzur in
                DyzurFormView(store: store, existingDyzur: dyzur)
            }
            .sheet(isPresented: $showingExport) {
                ShareSheet(items: [csvContent])
            }
        }
    }

    // MARK: - Summary section

    private var summarySection: some View {
        Section("Podsumowanie") {
            let total = store.totalHours()
            let totalH = Int(total)
            let totalM = Int((total - Double(totalH)) * 60)

            HStack {
                Label("Łączny czas", systemImage: "clock")
                Spacer()
                Text("\(totalH) godz. \(totalM) min.")
                    .fontWeight(.semibold)
                    .foregroundStyle(total > 0 ? .primary : .secondary)
            }
            HStack {
                Label("Dyżury tygodniowe", systemImage: "sun.max")
                Spacer()
                Text("\(store.totalWeekdayShifts)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Dyżury weekendowe", systemImage: "moon.stars")
                Spacer()
                Text("\(store.totalWeekendShifts)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Shifts section

    private var shiftsSection: some View {
        Section("Lista dyżurów") {
            if store.dyzury.isEmpty {
                Text("Brak dyżurów. Dodaj pierwszy dyżur.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(store.dyzury) { dyzur in
                    DyzurRow(dyzur: dyzur, dateFormatter: dateFormatter)
                        .contentShape(Rectangle())
                        .onTapGesture { editingDyzur = dyzur }
                }
                .onDelete { offsets in
                    store.remove(at: offsets)
                }
            }
        }
    }
}

// MARK: - Shift Row

private struct DyzurRow: View {
    let dyzur: Dyzur
    let dateFormatter: DateFormatter

    private var weekdayName: String {
        let idx = WorkDaysEngine.calendar.component(.weekday, from: dyzur.date) - 1
        return WorkDaysEngine.polishWeekdayNames[idx]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(dyzur.type.localizedName)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(dyzur.type.durationDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Text(dateFormatter.string(from: dyzur.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(weekdayName)
                    .font(.caption)
                    .foregroundStyle(dyzur.type == .weekend ? .orange : .secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ShareSheet (UIActivityViewController wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DyzuryView()
}
