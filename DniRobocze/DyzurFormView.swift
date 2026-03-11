import SwiftUI
import EventKit

struct DyzurFormView: View {
    @Environment(\.dismiss) private var dismiss

    let store: DyzuryStore
    var existingDyzur: Dyzur?

    @State private var selectedDate: Date
    @State private var selectedType: DyzurType
    @State private var addToCalendar = false
    @State private var calendarError: String?
    @State private var showingCalendarError = false

    init(store: DyzuryStore, existingDyzur: Dyzur? = nil) {
        self.store = store
        self.existingDyzur = existingDyzur
        _selectedDate = State(initialValue: existingDyzur?.date ?? Calendar.current.startOfDay(for: Date()))
        _selectedType = State(initialValue: existingDyzur?.type ?? Self.defaultType(for: existingDyzur?.date ?? Date()))
    }

    var isEditing: Bool { existingDyzur != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Data dyżuru") {
                    DatePicker(
                        "Data rozpoczęcia",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "pl_PL"))
                    .onChange(of: selectedDate) { _, newDate in
                        selectedType = Self.defaultType(for: newDate)
                    }
                }

                Section("Typ dyżuru") {
                    Picker("Typ dyżuru", selection: $selectedType) {
                        ForEach(DyzurType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Label("Czas trwania", systemImage: "clock")
                        Spacer()
                        Text(selectedType.durationDescription)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Opcje") {
                    Toggle(isOn: $addToCalendar) {
                        Label("Dodaj do kalendarza", systemImage: "calendar.badge.plus")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edytuj dyżur" : "Dodaj dyżur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Zapisz" : "Dodaj") {
                        save()
                    }
                }
            }
            .alert("Błąd kalendarza", isPresented: $showingCalendarError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(calendarError ?? "Nie udało się dodać dyżuru do kalendarza.")
            }
        }
    }

    // MARK: - Auto-detect type

    private static func defaultType(for date: Date) -> DyzurType {
        let weekday = WorkDaysEngine.calendar.component(.weekday, from: date)
        // weekday: 1=Sunday, 7=Saturday
        return (weekday == 1 || weekday == 7) ? .weekend : .weekday
    }

    // MARK: - Save

    private func save() {
        if isEditing, var updated = existingDyzur {
            updated.date = selectedDate
            updated.type = selectedType
            store.update(updated)
        } else {
            let dyzur = Dyzur(date: selectedDate, type: selectedType)
            store.add(dyzur)
        }

        if addToCalendar {
            addEventToCalendar()
        } else {
            dismiss()
        }
    }

    // MARK: - Calendar Integration

    private func addEventToCalendar() {
        let eventStore = EKEventStore()

        if #available(iOS 17.0, *) {
            eventStore.requestWriteOnlyAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        createCalendarEvent(in: eventStore)
                    } else {
                        calendarError = "Brak uprawnień do kalendarza. Sprawdź ustawienia aplikacji."
                        showingCalendarError = true
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        createCalendarEvent(in: eventStore)
                    } else {
                        calendarError = error.map { "Błąd: \($0.localizedDescription)" }
                            ?? "Brak uprawnień do kalendarza. Sprawdź ustawienia aplikacji."
                        showingCalendarError = true
                    }
                }
            }
        }
    }

    private func createCalendarEvent(in eventStore: EKEventStore) {
        let event = EKEvent(eventStore: eventStore)
        event.title = selectedType.localizedName
        event.startDate = selectedDate
        event.endDate = selectedDate.addingTimeInterval(selectedType.duration)
        event.notes = "Dodano przez aplikację Dni Robocze"
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            dismiss()
        } catch {
            calendarError = "Nie udało się zapisać zdarzenia: \(error.localizedDescription)"
            showingCalendarError = true
        }
    }
}

#Preview {
    DyzurFormView(store: DyzuryStore())
}
