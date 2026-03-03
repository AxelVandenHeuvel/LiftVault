import Foundation
import SwiftData

@Model
final class LogExercise {
    var name: String
    var order: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \LogSet.logExercise)
    var sets: [LogSet] = []
    var dailyLog: DailyLog?

    init(name: String, order: Int = 0) {
        self.name = name
        self.order = order
    }
}
