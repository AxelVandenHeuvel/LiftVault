import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var displayedMonth: Date
    @Query private var dailyLogs: [DailyLog]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Month navigation header
                HStack {
                    Button { changeMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(yearString)
                            .font(.caption.weight(.medium))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(monthString)
                            .font(.title.bold())
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    Button { changeMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal)

                // Calendar card
                VStack(spacing: 8) {
                    // Weekday headers
                    LazyVGrid(columns: columns) {
                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                            Text(symbol)
                                .font(.caption2.weight(.heavy))
                                .tracking(0.5)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Day cells
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                            if let date {
                                let isFuture = date > calendar.startOfDay(for: Date()).addingTimeInterval(86399)
                                if isFuture {
                                    DayCell(date: date, dotColor: nil)
                                        .opacity(0.3)
                                } else {
                                    NavigationLink(value: date) {
                                        DayCell(date: date, dotColor: dotColor(for: date))
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Color.clear
                                    .frame(height: 48)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.primary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

                // Open Today button
                NavigationLink(value: Date()) {
                    HStack(spacing: 12) {
                        Text("TODAY")
                            .font(.caption.weight(.heavy))
                            .tracking(2)

                        Spacer()

                        Text("Start Workout")
                            .font(.subheadline.weight(.semibold))

                        Image(systemName: "arrow.right")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)

                // Recent workouts
                if !recentWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT")
                            .font(.caption.weight(.heavy))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        ForEach(recentWorkouts) { log in
                            NavigationLink(value: log.date) {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(TemplateColor.color(for: log.templateColorName))
                                                .frame(width: 8, height: 8)
                                            Text(log.templateName ?? "Custom Workout")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                        }
                                        Text(shortDate(log.date))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(log.exercises.count)")
                                            .font(.title3.weight(.bold))
                                            .monospacedDigit()
                                            .foregroundStyle(Theme.accent)
                                        +
                                        Text(" ex")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)

                                        if let dur = log.duration, dur > 0 {
                                            Text(formatWorkoutDuration(dur))
                                                .font(.caption2.weight(.medium).monospacedDigit())
                                                .foregroundStyle(.tertiary)
                                        }
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Helpers

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: displayedMonth)
    }

    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                displayedMonth = newDate
            }
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

    private var recentWorkouts: [DailyLog] {
        Array(
            dailyLogs
                .filter { !$0.exercises.isEmpty && !Calendar.current.isDateInToday($0.date) && $0.date < Date() }
                .sorted(by: { $0.date > $1.date })
                .prefix(3)
        )
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func formatWorkoutDuration(_ seconds: TimeInterval) -> String {
        let totalMins = Int(seconds) / 60
        if totalMins < 60 { return "\(totalMins)m" }
        let hrs = totalMins / 60
        let mins = totalMins % 60
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }

    private func dotColor(for date: Date) -> Color? {
        guard let log = dailyLogs.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
              !log.exercises.isEmpty else { return nil }
        return TemplateColor.color(for: log.templateColorName)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let dotColor: Color?

    private let calendar = Calendar.current

    var body: some View {
        let isToday = calendar.isDateInToday(date)

        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.callout.weight(isToday ? .heavy : .regular))
                .monospacedDigit()
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isToday ? Theme.primary : Color.clear)
                )

            Circle()
                .fill(dotColor ?? Color.clear)
                .frame(width: 6, height: 6)
        }
        .frame(height: 48)
        .contentShape(Rectangle())
    }
}
