import Foundation
import SwiftData

@Model
final class Movement {
    var name: String
    var category: String

    /// Returns individual categories split from the comma-separated string.
    var categoryList: [String] {
        category.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    init(name: String, category: String = "Other") {
        self.name = name
        self.category = category
    }
}
