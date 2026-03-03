import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var displayedMonth = Date()
    @State private var showingSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("colorPalette") private var colorPalette = "Burgundy"

    var body: some View {
        TabView {
            NavigationStack {
                CalendarView(displayedMonth: $displayedMonth)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: Date.self) { date in
                        DayDetailView(date: date)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.body)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            NavigationStack {
                TemplateListView()
            }
            .tabItem {
                Label("Templates", systemImage: "list.bullet.rectangle.portrait")
            }

            NavigationStack {
                MovementLibraryView()
            }
            .tabItem {
                Label("Movements", systemImage: "figure.strengthtraining.traditional")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
        .id("theme-\(colorPalette)-\(isDarkMode)")
        .tint(Theme.primary)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showingSettings) {
            ThemeSettingsSheet(isDarkMode: $isDarkMode, colorPalette: $colorPalette)
        }
    }
}

// MARK: - Theme Settings Sheet

private struct ThemeSettingsSheet: View {
    @Binding var isDarkMode: Bool
    @Binding var colorPalette: String
    @Environment(\.dismiss) private var dismiss
    @Query private var dailyLogs: [DailyLog]
    @State private var csvFileURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                } header: {
                    Text("APPEARANCE")
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                }

                Section {
                    ForEach(ColorPalette.allCases) { palette in
                        Button {
                            colorPalette = palette.rawValue
                        } label: {
                            HStack(spacing: 14) {
                                HStack(spacing: 4) {
                                    Circle().fill(palette.primary).frame(width: 20, height: 20)
                                    Circle().fill(palette.accent).frame(width: 20, height: 20)
                                    Circle().fill(palette.secondary).frame(width: 20, height: 20)
                                }

                                Text(palette.rawValue)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if colorPalette == palette.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(palette.primary)
                                }
                            }
                            .frame(minHeight: 44)
                        }
                    }
                } header: {
                    Text("COLOR THEME")
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                }

                Section {
                    if let url = csvFileURL {
                        ShareLink(item: url) {
                            Label("Share CSV", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            csvFileURL = generateCSV()
                        } label: {
                            Label("Export Workout History", systemImage: "arrow.down.doc")
                        }
                    }
                } header: {
                    Text("DATA")
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                } footer: {
                    Text("Export all workouts as a CSV file.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func generateCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var csv = "Date,Template,Exercise,Set,Reps,Weight (lbs),Duration (min)\n"

        let sorted = dailyLogs
            .filter { !$0.exercises.isEmpty }
            .sorted { $0.date < $1.date }

        for log in sorted {
            let dateStr = dateFormatter.string(from: log.date)
            let template = (log.templateName ?? "").replacingOccurrences(of: ",", with: ";")
            let durationMin = log.duration.map { String(Int($0) / 60) } ?? ""

            for exercise in log.exercises.sorted(by: { $0.order < $1.order }) {
                let name = exercise.name.replacingOccurrences(of: ",", with: ";")
                let filledSets = exercise.sets.filter { $0.reps > 0 && $0.weight > 0 }
                for (i, set) in filledSets.enumerated() {
                    let w = set.weight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", set.weight)
                        : "\(set.weight)"
                    csv += "\(dateStr),\(template),\(name),\(i + 1),\(set.reps),\(w),\(durationMin)\n"
                }
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LiftVault_Export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutTemplate.self, DailyLog.self, Movement.self], inMemory: true)
}
