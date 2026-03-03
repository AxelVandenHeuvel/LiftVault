import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var displayedMonth: Date
    @Query private var dailyLogs: [DailyLog]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation header
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearString)
                    .font(.title2.bold())
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Weekday headers
            LazyVGrid(columns: columns) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date {
                        NavigationLink(value: date) {
                            DayCell(date: date, hasLog: hasLog(for: date))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        return days
    }

    private func hasLog(for date: Date) -> Bool {
        dailyLogs.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let hasLog: Bool

    private let calendar = Calendar.current

    var body: some View {
        let isToday = calendar.isDateInToday(date)

        Text("\(calendar.component(.day, from: date))")
            .font(.body)
            .fontWeight(isToday ? .bold : .regular)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isToday ? Color.blue.opacity(0.2) : Color.clear)
            )
            .overlay(
                Circle()
                    .fill(hasLog ? Color.green : Color.clear)
                    .frame(width: 6, height: 6)
                    .offset(y: 14)
            )
    }
}
