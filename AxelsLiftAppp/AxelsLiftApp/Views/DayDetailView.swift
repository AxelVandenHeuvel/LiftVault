import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var dailyLogs: [DailyLog]
    @Query private var templates: [WorkoutTemplate]
    @State private var showTemplateSheet = false

    private var log: DailyLog? {
        dailyLogs.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        List {
            if let log, !log.exercises.isEmpty {
                Section("Exercises") {
                    ForEach(log.exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.headline)
                            Spacer()
                            Text("\(exercise.sets)x\(exercise.reps)")
                                .foregroundStyle(.secondary)
                            if exercise.weight > 0 {
                                Text("@ \(exercise.weight, specifier: "%.1f") lbs")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Workout",
                    systemImage: "dumbbell",
                    description: Text("Apply a template to get started.")
                )
            }
        }
        .navigationTitle(formattedDate)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Apply Template") {
                    showTemplateSheet = true
                }
            }
        }
        .sheet(isPresented: $showTemplateSheet) {
            TemplatePickerSheet(date: date, existingLog: log)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Template Picker

struct TemplatePickerSheet: View {
    let date: Date
    let existingLog: DailyLog?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var templates: [WorkoutTemplate]

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.badge.plus",
                        description: Text("Create a template first.")
                    )
                } else {
                    List(templates) { template in
                        Button {
                            applyTemplate(template)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.headline)
                                Text("\(template.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    /// Copies exercises from a WorkoutTemplate into a DailyLog for the given date.
    private func applyTemplate(_ template: WorkoutTemplate) {
        let log = existingLog ?? DailyLog(date: date)

        for exercise in template.exercises {
            let copy = LogExercise(
                name: exercise.name,
                sets: exercise.sets,
                reps: exercise.reps,
                weight: exercise.weight
            )
            log.exercises.append(copy)
        }

        if existingLog == nil {
            modelContext.insert(log)
        }
    }
}
