import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CountWorkDaysView()
                .tabItem {
                    Label("Policz dni", systemImage: "calendar.badge.clock")
                }

            AddWorkDaysView()
                .tabItem {
                    Label("Dodaj dni", systemImage: "calendar.badge.plus")
                }

            HolidaysView()
                .tabItem {
                    Label("Święta", systemImage: "star.fill")
                }

            DyzuryView()
                .tabItem {
                    Label("Dyżury", systemImage: "stethoscope")
                }
        }
    }
}

#Preview {
    ContentView()
}
