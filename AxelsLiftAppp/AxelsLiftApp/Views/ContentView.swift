import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var displayedMonth = Date()

    var body: some View {
        NavigationStack {
            CalendarView(displayedMonth: $displayedMonth)
                .navigationTitle("Lift Tracker")
                .navigationDestination(for: Date.self) { date in
                    DayDetailView(date: date)
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutTemplate.self, DailyLog.self], inMemory: true)
}
