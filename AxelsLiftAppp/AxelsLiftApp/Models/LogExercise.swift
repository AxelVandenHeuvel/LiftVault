import Foundation
import SwiftData

@Model
final class LogExercise {
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var dailyLog: DailyLog?

    init(name: String, sets: Int = 3, reps: Int = 10, weight: Double = 0) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
    }
}
