import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var name: String
    var colorName: String = "blue"
    var folder: TemplateFolder?
    @Relationship(deleteRule: .cascade, inverse: \Exercise.template)
    var exercises: [Exercise] = []

    init(name: String, colorName: String = "blue", exercises: [Exercise] = []) {
        self.name = name
        self.colorName = colorName
        self.exercises = exercises
    }
}
