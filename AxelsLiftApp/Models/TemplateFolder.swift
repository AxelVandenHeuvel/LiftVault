import Foundation
import SwiftData

@Model
final class TemplateFolder {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.folder)
    var templates: [WorkoutTemplate] = []

    init(name: String) {
        self.name = name
    }
}
