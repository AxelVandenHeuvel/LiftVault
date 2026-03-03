import Foundation
import SwiftData

@Model
final class LogSet {
    var reps: Int
    var weight: Double
    var logExercise: LogExercise?

    init(reps: Int = 0, weight: Double = 0) {
        self.reps = reps
        self.weight = weight
    }
}
