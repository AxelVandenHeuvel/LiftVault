import SwiftUI

// MARK: - Color Palette

enum ColorPalette: String, CaseIterable, Identifiable {
    case burgundy = "Burgundy"
    case purple = "Purple"
    case blue = "Blue"
    case forest = "Forest"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .burgundy: Color(red: 0.608, green: 0.137, blue: 0.208)  // #9B2335
        case .purple:   Color(red: 0.553, green: 0.388, blue: 0.812)  // #8D63CF
        case .blue:     Color(red: 0.220, green: 0.463, blue: 0.831)  // #3876D4
        case .forest:   Color(red: 0.224, green: 0.529, blue: 0.380)  // #398761
        }
    }

    var secondary: Color {
        switch self {
        case .burgundy: Color(red: 0.420, green: 0.082, blue: 0.145)  // #6B1525
        case .purple:   Color(red: 0.353, green: 0.216, blue: 0.569)  // #5A3791
        case .blue:     Color(red: 0.137, green: 0.318, blue: 0.612)  // #23519C
        case .forest:   Color(red: 0.145, green: 0.376, blue: 0.263)  // #256043
        }
    }

    var accent: Color {
        switch self {
        case .burgundy: Color(red: 0.788, green: 0.314, blue: 0.416)  // #C9506A
        case .purple:   Color(red: 0.718, green: 0.557, blue: 0.918)  // #B78EEA
        case .blue:     Color(red: 0.400, green: 0.620, blue: 0.933)  // #669EEE
        case .forest:   Color(red: 0.384, green: 0.714, blue: 0.529)  // #62B687
        }
    }

    var swatch: Color { primary }
}

// MARK: - Theme (reads from UserDefaults)

enum Theme {
    private static var currentPalette: ColorPalette {
        let raw = UserDefaults.standard.string(forKey: "colorPalette") ?? "Burgundy"
        return ColorPalette(rawValue: raw) ?? .burgundy
    }

    static var primary: Color { currentPalette.primary }
    static var secondary: Color { currentPalette.secondary }
    static var accent: Color { currentPalette.accent }
}
