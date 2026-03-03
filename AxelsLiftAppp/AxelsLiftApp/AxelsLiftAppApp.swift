import SwiftUI
import SwiftData

@main
struct RepVaultApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WorkoutTemplate.self, DailyLog.self])
    }
}
