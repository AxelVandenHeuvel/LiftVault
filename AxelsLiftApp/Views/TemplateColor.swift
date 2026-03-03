import SwiftUI

struct TemplateColor {
    let name: String
    let color: Color

    static let all: [TemplateColor] = [
        TemplateColor(name: "red", color: .red),
        TemplateColor(name: "orange", color: .orange),
        TemplateColor(name: "yellow", color: .yellow),
        TemplateColor(name: "green", color: .green),
        TemplateColor(name: "teal", color: .teal),
        TemplateColor(name: "blue", color: .blue),
        TemplateColor(name: "indigo", color: .indigo),
        TemplateColor(name: "purple", color: .purple),
        TemplateColor(name: "pink", color: .pink),
    ]

    static func color(for name: String?) -> Color {
        guard let name else { return .gray }
        // Check named presets first
        if let preset = all.first(where: { $0.name == name }) {
            return preset.color
        }
        // Try hex
        if let c = Color(hex: name) {
            return c
        }
        return .gray
    }

    static func hexString(from color: Color) -> String {
        let components = UIColor(color).cgColor.components ?? [0, 0, 0, 1]
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
