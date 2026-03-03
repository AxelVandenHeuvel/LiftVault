import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var templateColorName: String?
    var templateName: String?
    var notes: String = ""
    var startTime: Date?
    var endTime: Date?
    var isFinished: Bool = false
    var wasTimedOut: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \LogExercise.dailyLog)
    var exercises: [LogExercise] = []

    /// Auto-timeout: 5 hours max workout duration.
    static let maxDuration: TimeInterval = 5 * 60 * 60

    init(date: Date, exercises: [LogExercise] = []) {
        self.date = date
        self.exercises = exercises
    }

    /// Call when a set is logged to track workout duration.
    func stampSetLogged() {
        let now = Date()
        if startTime == nil { startTime = now }
        if !isFinished { endTime = now }
    }

    /// Explicitly finish the workout.
    func finishWorkout() {
        guard !isFinished else { return }
        endTime = Date()
        isFinished = true
    }

    /// Workout duration in seconds, or nil if not started.
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }

    /// Whether the workout timer is actively running.
    var isActive: Bool {
        startTime != nil && !isFinished
    }
}
