import SwiftUI
import SwiftData

@main
struct RepVaultApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            TemplateFolder.self,
            WorkoutTemplate.self, Exercise.self,
            DailyLog.self, LogExercise.self, LogSet.self,
            Movement.self,
        ])

        var resolved: ModelContainer
        do {
            resolved = try ModelContainer(for: schema)
        } catch {
            // Schema changed — destroy the old store and retry
            if let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first {
                for ext in ["store", "store-shm", "store-wal"] {
                    let url = appSupport.appendingPathComponent("default.\(ext)")
                    try? FileManager.default.removeItem(at: url)
                }
            }
            do {
                resolved = try ModelContainer(for: schema)
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }

        let context = resolved.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Movement>())) ?? 0
        if count == 0 {
            for (name, category) in Self.defaultMovements {
                context.insert(Movement(name: name, category: category))
            }
        }

        // Migrate old categories (Legs, Arms, Compound → specific muscle groups)
        let legsPredicate = #Predicate<Movement> { $0.category == "Legs" }
        let hasOldCategories = ((try? context.fetchCount(FetchDescriptor<Movement>(predicate: legsPredicate))) ?? 0) > 0
        if hasOldCategories {
            let allMovements = (try? context.fetch(FetchDescriptor<Movement>())) ?? []
            for m in allMovements { context.delete(m) }
            for (name, category) in Self.defaultMovements {
                context.insert(Movement(name: name, category: category))
            }
        }
        let folderCount = (try? context.fetchCount(FetchDescriptor<TemplateFolder>())) ?? 0
        if folderCount == 0 {
            context.insert(TemplateFolder(name: "My Templates"))
        }

        // Remove starter templates from existing installs
        let starterPredicate = #Predicate<TemplateFolder> { $0.name == "Starter Templates" }
        if let starterFolders = try? context.fetch(FetchDescriptor<TemplateFolder>(predicate: starterPredicate)) {
            for folder in starterFolders {
                context.delete(folder)
            }
        }

        self.container = resolved
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    // MARK: - Default Movement Library

    private static let defaultMovements: [(String, String)] = [
        // Chest (22)
        ("Barbell Bench Press", "Chest"),
        ("Incline Barbell Bench Press", "Chest"),
        ("Decline Barbell Bench Press", "Chest"),
        ("Dumbbell Bench Press", "Chest"),
        ("Incline Dumbbell Bench Press", "Chest"),
        ("Decline Dumbbell Bench Press", "Chest"),
        ("Dumbbell Flyes", "Chest"),
        ("Incline Dumbbell Flyes", "Chest"),
        ("Cable Flyes", "Chest"),
        ("Low Cable Flyes", "Chest"),
        ("High Cable Flyes", "Chest"),
        ("Push-Ups", "Chest"),
        ("Diamond Push-Ups", "Chest, Triceps"),
        ("Wide Push-Ups", "Chest"),
        ("Decline Push-Ups", "Chest"),
        ("Chest Dips", "Chest, Triceps"),
        ("Machine Chest Press", "Chest"),
        ("Incline Machine Press", "Chest"),
        ("Pec Deck", "Chest"),
        ("Landmine Press", "Chest, Shoulders"),
        ("Svend Press", "Chest"),
        ("Floor Press", "Chest, Triceps"),

        // Back (22)
        ("Barbell Row", "Back"),
        ("Dumbbell Row", "Back"),
        ("Pendlay Row", "Back"),
        ("Pull-Ups", "Back, Biceps"),
        ("Chin-Ups", "Back, Biceps"),
        ("Neutral Grip Pull-Ups", "Back, Biceps"),
        ("Lat Pulldown", "Back"),
        ("Close-Grip Lat Pulldown", "Back"),
        ("Wide-Grip Lat Pulldown", "Back"),
        ("Seated Cable Row", "Back"),
        ("T-Bar Row", "Back"),
        ("Face Pulls", "Back, Shoulders"),
        ("Straight-Arm Pulldown", "Back"),
        ("Meadows Row", "Back"),
        ("Chest-Supported Row", "Back"),
        ("Inverted Row", "Back"),
        ("Cable Pullover", "Back"),
        ("Single-Arm Cable Row", "Back"),
        ("Rack Pull", "Back, Hamstrings"),
        ("Seal Row", "Back"),
        ("Kroc Row", "Back"),
        ("Machine Row", "Back"),

        // Shoulders (22)
        ("Overhead Press", "Shoulders"),
        ("Dumbbell Shoulder Press", "Shoulders"),
        ("Arnold Press", "Shoulders"),
        ("Lateral Raises", "Shoulders"),
        ("Cable Lateral Raises", "Shoulders"),
        ("Front Raises", "Shoulders"),
        ("Reverse Flyes", "Shoulders, Back"),
        ("Upright Row", "Shoulders"),
        ("Machine Shoulder Press", "Shoulders"),
        ("Behind-the-Neck Press", "Shoulders"),
        ("Dumbbell Shrug", "Shoulders"),
        ("Barbell Shrug", "Shoulders"),
        ("Lu Raises", "Shoulders"),
        ("Plate Front Raise", "Shoulders"),
        ("Cable Face Pull", "Shoulders, Back"),
        ("Seated Lateral Raises", "Shoulders"),
        ("Landmine Lateral Raise", "Shoulders"),
        ("Machine Lateral Raise", "Shoulders"),
        ("Incline Y-Raises", "Shoulders"),
        ("Bus Drivers", "Shoulders"),
        ("Band Pull-Aparts", "Shoulders, Back"),
        ("Bradford Press", "Shoulders"),

        // Quads / Hamstrings / Glutes / Calves (28) — formerly "Legs"
        ("Barbell Squat", "Quads, Hamstrings, Glutes"),
        ("Front Squat", "Quads, Glutes"),
        ("Goblet Squat", "Quads, Glutes"),
        ("Hack Squat", "Quads"),
        ("Leg Press", "Quads, Glutes"),
        ("Single-Leg Leg Press", "Quads, Glutes"),
        ("Romanian Deadlift", "Hamstrings, Glutes"),
        ("Single-Leg Romanian Deadlift", "Hamstrings, Glutes"),
        ("Bulgarian Split Squat", "Quads, Glutes"),
        ("Lunges", "Quads, Glutes"),
        ("Walking Lunges", "Quads, Glutes"),
        ("Reverse Lunges", "Quads, Glutes, Hamstrings"),
        ("Curtsy Lunges", "Quads, Glutes"),
        ("Leg Extension", "Quads"),
        ("Leg Curl", "Hamstrings"),
        ("Seated Leg Curl", "Hamstrings"),
        ("Nordic Hamstring Curl", "Hamstrings"),
        ("Hip Thrust", "Glutes, Hamstrings"),
        ("Single-Leg Hip Thrust", "Glutes, Hamstrings"),
        ("Glute Bridge", "Glutes"),
        ("Calf Raises", "Calves"),
        ("Seated Calf Raises", "Calves"),
        ("Donkey Calf Raises", "Calves"),
        ("Smith Machine Squat", "Quads, Glutes"),
        ("Belt Squat", "Quads, Glutes"),
        ("Step-Ups", "Quads, Glutes"),
        ("Sissy Squat", "Quads"),
        ("Box Squat", "Quads, Hamstrings, Glutes"),

        // Biceps / Triceps / Forearms (26) — formerly "Arms"
        ("Barbell Curl", "Biceps"),
        ("Dumbbell Curl", "Biceps"),
        ("Hammer Curl", "Biceps, Forearms"),
        ("Preacher Curl", "Biceps"),
        ("Cable Curl", "Biceps"),
        ("Incline Dumbbell Curl", "Biceps"),
        ("Concentration Curl", "Biceps"),
        ("EZ-Bar Curl", "Biceps"),
        ("Spider Curl", "Biceps"),
        ("Reverse Curl", "Forearms, Biceps"),
        ("Zottman Curl", "Biceps, Forearms"),
        ("Cross-Body Hammer Curl", "Biceps, Forearms"),
        ("21s Curl", "Biceps"),
        ("Tricep Pushdown", "Triceps"),
        ("Rope Tricep Pushdown", "Triceps"),
        ("Skull Crushers", "Triceps"),
        ("Overhead Tricep Extension", "Triceps"),
        ("Cable Overhead Tricep Extension", "Triceps"),
        ("Close-Grip Bench Press", "Triceps, Chest"),
        ("Tricep Dips", "Triceps, Chest"),
        ("Tricep Kickback", "Triceps"),
        ("JM Press", "Triceps"),
        ("Tate Press", "Triceps"),
        ("Wrist Curl", "Forearms"),
        ("Reverse Wrist Curl", "Forearms"),
        ("Forearm Roller", "Forearms"),

        // Multi-joint / Olympic (16) — formerly "Compound"
        ("Deadlift", "Hamstrings, Back, Glutes"),
        ("Sumo Deadlift", "Hamstrings, Glutes, Quads"),
        ("Trap Bar Deadlift", "Quads, Hamstrings, Back"),
        ("Power Clean", "Quads, Hamstrings, Shoulders"),
        ("Clean and Press", "Shoulders, Quads, Hamstrings"),
        ("Hang Clean", "Hamstrings, Back, Shoulders"),
        ("Snatch", "Shoulders, Quads, Hamstrings"),
        ("Muscle Snatch", "Shoulders, Back"),
        ("Thruster", "Quads, Shoulders"),
        ("Push Press", "Shoulders, Quads"),
        ("Farmer's Walk", "Forearms, Core"),
        ("Turkish Get-Up", "Core, Shoulders"),
        ("Kettlebell Swing", "Hamstrings, Glutes, Core"),
        ("Man Maker", "Chest, Shoulders, Quads"),
        ("Devil Press", "Shoulders, Hamstrings, Chest"),
        ("Sled Push", "Quads, Glutes, Calves"),

        // Core (18)
        ("Plank", "Core"),
        ("Side Plank", "Core"),
        ("Hanging Leg Raise", "Core"),
        ("Hanging Knee Raise", "Core"),
        ("Cable Crunch", "Core"),
        ("Ab Wheel Rollout", "Core"),
        ("Russian Twist", "Core"),
        ("Bicycle Crunch", "Core"),
        ("Dragon Flag", "Core"),
        ("Pallof Press", "Core"),
        ("Decline Sit-Up", "Core"),
        ("Dead Bug", "Core"),
        ("Bird Dog", "Core"),
        ("Mountain Climbers", "Core"),
        ("Woodchops", "Core"),
        ("Copenhagen Plank", "Core"),
        ("L-Sit", "Core"),
        ("Toe Touches", "Core"),
    ]
}
