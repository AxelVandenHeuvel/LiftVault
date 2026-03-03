import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var setCount: Int = 3
    var order: Int = 0
    var template: WorkoutTemplate?

    init(name: String, setCount: Int = 3, order: Int = 0) {
        self.name = name
        self.setCount = setCount
        self.order = order
    }
}
