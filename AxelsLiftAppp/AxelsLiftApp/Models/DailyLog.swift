import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    @Relationship(deleteRule: .cascade, inverse: \LogExercise.dailyLog)
    var exercises: [LogExercise] = []

    init(date: Date, exercises: [LogExercise] = []) {
        self.date = date
        self.exercises = exercises
    }
}
