import SwiftUI
import SwiftData
import FoundationModels

// MARK: - Generable Structs (parsed by on-device AI)

@available(iOS 26, *)
@Generable
struct ParsedWorkout {
    @Guide(description: "List of exercises the user wants to log")
    var exercises: [ParsedExercise]
}

@available(iOS 26, *)
@Generable
struct ParsedExercise {
    @Guide(description: "Name of the exercise, e.g. 'bench press', 'squat', 'deadlift'")
    var name: String

    @Guide(description: "List of sets for this exercise")
    var sets: [ParsedSet]
}

@available(iOS 26, *)
@Generable
struct ParsedSet {
    @Guide(description: "Number of reps for this set", .range(1...100))
    var reps: Int

    @Guide(description: "Weight in pounds for this set", .range(0...1000))
    var weight: Double
}

// MARK: - Workout Input Sheet

@available(iOS 26, *)
struct WorkoutInputSheet: View {
    let date: Date
    let existingLog: DailyLog?
    let movements: [Movement]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Describe your workout in natural language")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("e.g. 3 sets of bench at 185, first 2 for 4 reps, last for 5", text: $inputText, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Tap the microphone on your keyboard to use voice")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("Powered by Apple Foundation Models")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("Requires iPhone 16 Pro or later with Apple Intelligence enabled.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Log by AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await processInput() }
                    } label: {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Text("Add")
                                .bold()
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
                }
            }
        }
    }

    private func processInput() async {
        isProcessing = true
        errorMessage = nil

        do {
            let instructions = """
            You are a workout logging assistant. Parse the user's natural language into structured workout data.

            CRITICAL: When the user says "N sets", you MUST create N separate ParsedSet entries in the sets array. \
            For example "3 sets of bench at 185 10 reps each" = 3 ParsedSet objects each with reps=10 weight=185.

            Match exercise names to common gym exercises. For example:
            - "bench" = "Bench Press"
            - "squat" = "Squat"
            - "deadlift" = "Deadlift"
            - "OHP" or "overhead press" = "Overhead Press"
            - "curl" = "Curl"
            - "row" = "Row"
            - "incline bench" = "Incline Bench Press"
            - "rdl" = "Romanian Deadlift"
            - "lat pulldown" = "Lat Pulldown"
            Use the common short name. Do NOT add "Barbell" or "Dumbbell" prefix unless the user specifies it.
            """

            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(
                to: inputText,
                generating: ParsedWorkout.self
            )

            let parsed = response.content
            await MainActor.run {
                applyParsedWorkout(parsed)
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't parse that. Try rephrasing."
                isProcessing = false
            }
        }
    }

    private func applyParsedWorkout(_ parsed: ParsedWorkout) {
        let log = existingLog ?? DailyLog(date: date)

        var nextOrder = (log.exercises.map(\.order).max() ?? -1) + 1

        for parsedExercise in parsed.exercises {
            let matchedName = bestMovementMatch(for: parsedExercise.name)

            // Use existing exercise if this movement is already in today's log
            let exercise: LogExercise
            if let existing = log.exercises.first(where: { $0.name == matchedName }) {
                exercise = existing
            } else {
                exercise = LogExercise(name: matchedName, order: nextOrder)
                log.exercises.append(exercise)
                nextOrder += 1
            }

            // Replace empty (0/0) sets first, then append the rest
            let emptySets = exercise.sets.filter { $0.reps == 0 && $0.weight == 0 }
            var emptyIndex = 0

            for parsedSet in parsedExercise.sets {
                if emptyIndex < emptySets.count {
                    // Overwrite the empty set in place
                    emptySets[emptyIndex].reps = parsedSet.reps
                    emptySets[emptyIndex].weight = parsedSet.weight
                    emptyIndex += 1
                } else {
                    exercise.sets.append(LogSet(reps: parsedSet.reps, weight: parsedSet.weight))
                }
            }
        }

        if existingLog == nil {
            modelContext.insert(log)
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // Common gym lingo → exact movement name in our library
    private static let gymAliases: [String: String] = [
        "bench": "Barbell Bench Press",
        "bench press": "Barbell Bench Press",
        "flat bench": "Barbell Bench Press",
        "incline bench": "Incline Barbell Bench Press",
        "decline bench": "Decline Barbell Bench Press",
        "db bench": "Dumbbell Bench Press",
        "dumbbell bench": "Dumbbell Bench Press",
        "incline db bench": "Incline Dumbbell Bench Press",
        "squat": "Barbell Squat",
        "squats": "Barbell Squat",
        "back squat": "Barbell Squat",
        "front squat": "Front Squat",
        "hack squat": "Hack Squat",
        "goblet squat": "Goblet Squat",
        "deadlift": "Deadlift",
        "sumo deadlift": "Sumo Deadlift",
        "trap bar deadlift": "Trap Bar Deadlift",
        "rdl": "Romanian Deadlift",
        "romanian deadlift": "Romanian Deadlift",
        "ohp": "Overhead Press",
        "overhead press": "Overhead Press",
        "shoulder press": "Dumbbell Shoulder Press",
        "military press": "Overhead Press",
        "curl": "Barbell Curl",
        "curls": "Barbell Curl",
        "bicep curl": "Barbell Curl",
        "bicep curls": "Barbell Curl",
        "hammer curl": "Hammer Curl",
        "hammer curls": "Hammer Curl",
        "preacher curl": "Preacher Curl",
        "db curl": "Dumbbell Curl",
        "dumbbell curl": "Dumbbell Curl",
        "row": "Barbell Row",
        "rows": "Barbell Row",
        "barbell row": "Barbell Row",
        "db row": "Dumbbell Row",
        "dumbbell row": "Dumbbell Row",
        "cable row": "Seated Cable Row",
        "seated row": "Seated Cable Row",
        "t-bar row": "T-Bar Row",
        "pullup": "Pull-Ups",
        "pullups": "Pull-Ups",
        "pull up": "Pull-Ups",
        "pull ups": "Pull-Ups",
        "chinup": "Chin-Ups",
        "chinups": "Chin-Ups",
        "chin up": "Chin-Ups",
        "chin ups": "Chin-Ups",
        "lat pulldown": "Lat Pulldown",
        "pulldown": "Lat Pulldown",
        "dip": "Chest Dips",
        "dips": "Chest Dips",
        "tricep dip": "Tricep Dips",
        "tricep dips": "Tricep Dips",
        "skull crusher": "Skull Crushers",
        "skull crushers": "Skull Crushers",
        "skullcrusher": "Skull Crushers",
        "skullcrushers": "Skull Crushers",
        "tricep pushdown": "Tricep Pushdown",
        "pushdown": "Tricep Pushdown",
        "pushdowns": "Tricep Pushdown",
        "lateral raise": "Lateral Raises",
        "lateral raises": "Lateral Raises",
        "lat raise": "Lateral Raises",
        "lat raises": "Lateral Raises",
        "face pull": "Face Pulls",
        "face pulls": "Face Pulls",
        "shrug": "Dumbbell Shrug",
        "shrugs": "Dumbbell Shrug",
        "fly": "Dumbbell Flyes",
        "flyes": "Dumbbell Flyes",
        "flies": "Dumbbell Flyes",
        "cable fly": "Cable Flyes",
        "cable flies": "Cable Flyes",
        "cable flyes": "Cable Flyes",
        "leg press": "Leg Press",
        "leg curl": "Leg Curl",
        "leg extension": "Leg Extension",
        "hip thrust": "Hip Thrust",
        "hip thrusts": "Hip Thrust",
        "calf raise": "Calf Raises",
        "calf raises": "Calf Raises",
        "lunge": "Lunges",
        "lunges": "Lunges",
        "walking lunge": "Walking Lunges",
        "walking lunges": "Walking Lunges",
        "bulgarian": "Bulgarian Split Squat",
        "bulgarian split squat": "Bulgarian Split Squat",
        "push up": "Push-Ups",
        "push ups": "Push-Ups",
        "pushup": "Push-Ups",
        "pushups": "Push-Ups",
        "plank": "Plank",
        "leg raise": "Hanging Leg Raise",
        "hanging leg raise": "Hanging Leg Raise",
        "ab wheel": "Ab Wheel Rollout",
        "arnold press": "Arnold Press",
        "clean": "Power Clean",
        "power clean": "Power Clean",
        "snatch": "Snatch",
        "thruster": "Thruster",
        "thrusters": "Thruster",
        "farmer walk": "Farmer's Walk",
        "farmers walk": "Farmer's Walk",
        "farmer's walk": "Farmer's Walk",
        "kettlebell swing": "Kettlebell Swing",
        "kb swing": "Kettlebell Swing",
    ]

    private func bestMovementMatch(for name: String) -> String {
        let lowered = name.lowercased().trimmingCharacters(in: .whitespaces)

        // 1. Check gym lingo aliases first (most reliable)
        if let aliased = Self.gymAliases[lowered] {
            return aliased
        }

        // 2. Exact match against movement library
        if let match = movements.first(where: { $0.name.lowercased() == lowered }) {
            return match.name
        }

        // 3. Contains match — prefer shortest name (most specific)
        let containsMatches = movements.filter { $0.name.lowercased().contains(lowered) }
        if let best = containsMatches.min(by: { $0.name.count < $1.name.count }) {
            return best.name
        }

        // 4. Reverse contains (input contains movement name) — prefer longest name
        let reverseMatches = movements.filter { lowered.contains($0.name.lowercased()) }
        if let best = reverseMatches.max(by: { $0.name.count < $1.name.count }) {
            return best.name
        }

        // 5. Word overlap scoring
        let inputWords = Set(lowered.split(separator: " ").map(String.init))
        var bestMatch: Movement?
        var bestScore = 0

        for movement in movements {
            let movementWords = Set(movement.name.lowercased().split(separator: " ").map(String.init))
            let overlap = inputWords.intersection(movementWords).count
            if overlap > bestScore {
                bestScore = overlap
                bestMatch = movement
            }
        }

        if let bestMatch, bestScore > 0 {
            return bestMatch.name
        }

        // 6. Fallback: use the AI's name as-is
        return name
    }
}
