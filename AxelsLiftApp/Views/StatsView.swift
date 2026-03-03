import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var dailyLogs: [DailyLog]
    @Query private var movements: [Movement]
    @State private var timeframe: Timeframe = .week
    @State private var barsAnimated = false
    @State private var bodyPartMetric: BodyPartMetric = .sets

    enum BodyPartMetric: String, CaseIterable {
        case sets = "Sets"
        case reps = "Reps"
        case volume = "Volume"
    }

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    private var startDate: Date {
        let cal = Calendar.current
        switch timeframe {
        case .week: return cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month: return cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .year: return cal.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        }
    }

    private var filteredLogs: [DailyLog] {
        dailyLogs.filter { $0.date >= startDate && !$0.exercises.isEmpty }
    }

    private var workoutDays: Int {
        filteredLogs.count
    }

    private var totalSets: Int {
        filteredLogs.flatMap(\.exercises).flatMap(\.sets).filter { $0.reps > 0 && $0.weight > 0 }.count
    }

    private var totalReps: Int {
        filteredLogs.flatMap(\.exercises).flatMap(\.sets).filter { $0.reps > 0 && $0.weight > 0 }.reduce(0) { $0 + $1.reps }
    }

    private var movementLookup: [String: String] {
        Dictionary(uniqueKeysWithValues: movements.map { ($0.name, $0.category) })
    }

    private var setsByBodyPart: [(String, Int)] {
        var counts: [String: Int] = [:]
        let lookup = movementLookup
        for log in filteredLogs {
            for exercise in log.exercises {
                let category = lookup[exercise.name] ?? "Other"
                let categories = category.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let filledSets = exercise.sets.filter { $0.reps > 0 && $0.weight > 0 }.count
                for cat in categories {
                    counts[cat, default: 0] += filledSets
                }
            }
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var repsByBodyPart: [(String, Int)] {
        var counts: [String: Int] = [:]
        let lookup = movementLookup
        for log in filteredLogs {
            for exercise in log.exercises {
                let category = lookup[exercise.name] ?? "Other"
                let categories = category.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let filledReps = exercise.sets.filter { $0.reps > 0 && $0.weight > 0 }.reduce(0) { $0 + $1.reps }
                for cat in categories {
                    counts[cat, default: 0] += filledReps
                }
            }
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var volumeByBodyPart: [(String, Int)] {
        var counts: [String: Double] = [:]
        let lookup = movementLookup
        for log in filteredLogs {
            for exercise in log.exercises {
                let category = lookup[exercise.name] ?? "Other"
                let categories = category.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let vol = exercise.sets.filter { $0.reps > 0 && $0.weight > 0 }.reduce(0.0) { $0 + Double($1.reps) * $1.weight }
                for cat in categories {
                    counts[cat, default: 0] += vol
                }
            }
        }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, Int($0.value)) }
    }

    private var bodyPartData: [(String, Int)] {
        switch bodyPartMetric {
        case .sets: return setsByBodyPart
        case .reps: return repsByBodyPart
        case .volume: return volumeByBodyPart
        }
    }

    private var maxBodyPartValue: Int {
        bodyPartData.first?.1 ?? 1
    }

    private var templateUsage: [(String, Int, String)] {
        var counts: [String: (count: Int, color: String)] = [:]
        for log in filteredLogs {
            if let name = log.templateName, !name.isEmpty {
                let existing = counts[name]
                counts[name] = (
                    count: (existing?.count ?? 0) + 1,
                    color: log.templateColorName ?? "blue"
                )
            }
        }
        return counts
            .map { (name: $0.key, count: $0.value.count, color: $0.value.color) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timeframe picker
                Picker("Timeframe", selection: $timeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { tf in
                        Text(tf.rawValue).tag(tf)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: timeframe) {
                    barsAnimated = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        barsAnimated = true
                    }
                }

                // Summary cards
                HStack(spacing: 12) {
                    StatCard(title: "Workouts", value: "\(workoutDays)", icon: "calendar", accent: Theme.primary)
                    StatCard(title: "Sets", value: "\(totalSets)", icon: "number.square", accent: Theme.accent)
                    StatCard(title: "Reps", value: "\(totalReps)", icon: "flame.fill", accent: Theme.primary)
                }
                .padding(.horizontal)

                // Body parts chart
                if !bodyPartData.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("BODY PARTS")
                                .font(.caption.weight(.heavy))
                                .tracking(2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Picker("Metric", selection: $bodyPartMetric) {
                                ForEach(BodyPartMetric.allCases, id: \.self) { m in
                                    Text(m.rawValue).tag(m)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                            .onChange(of: bodyPartMetric) {
                                barsAnimated = false
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    barsAnimated = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 10) {
                            ForEach(Array(bodyPartData.enumerated()), id: \.element.0) { index, pair in
                                let (category, count) = pair
                                HStack(spacing: 12) {
                                    Text(category)
                                        .font(.subheadline)
                                        .frame(width: 80, alignment: .leading)

                                    GeometryReader { geo in
                                        Capsule()
                                            .fill(colorForCategory(category))
                                            .frame(
                                                width: barsAnimated
                                                    ? geo.size.width * CGFloat(count) / CGFloat(maxBodyPartValue)
                                                    : 0
                                            )
                                            .animation(
                                                .spring(response: 0.6, dampingFraction: 0.7)
                                                    .delay(Double(index) * 0.08),
                                                value: barsAnimated
                                            )
                                    }
                                    .frame(height: 22)

                                    Text(bodyPartMetric == .volume ? formatVolume(Double(count)) : "\(count)")
                                        .font(.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                        .frame(minWidth: 34, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                }

                // Template usage
                if !templateUsage.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("TEMPLATES")
                            .font(.caption.weight(.heavy))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 10) {
                            ForEach(templateUsage, id: \.0) { name, count, colorName in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(TemplateColor.color(for: colorName))
                                        .frame(width: 4, height: 28)

                                    Text(name)
                                        .font(.subheadline.weight(.medium))

                                    Spacer()

                                    Text("\(count) day\(count == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                }

                if filteredLogs.isEmpty {
                    VStack(spacing: 16) {
                        Text("—")
                            .font(.system(size: 48, weight: .ultraLight, design: .serif))
                            .foregroundStyle(Theme.primary.opacity(0.4))
                        Text("No data yet")
                            .font(.headline)
                        Text("Log some workouts to see your stats here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Stats")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                barsAnimated = true
            }
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Chest": return .red
        case "Back": return .blue
        case "Shoulders": return .orange
        case "Quads": return .green
        case "Hamstrings": return .mint
        case "Glutes": return .pink
        case "Calves": return .teal
        case "Biceps": return .purple
        case "Triceps": return .indigo
        case "Forearms": return .brown
        case "Core": return .yellow
        default: return .gray
        }
    }

    private func formatVolume(_ lbs: Double) -> String {
        if lbs >= 1_000_000 {
            return String(format: "%.1fM", lbs / 1_000_000)
        } else if lbs >= 10_000 {
            return String(format: "%.0fK", lbs / 1_000)
        } else if lbs >= 1_000 {
            return String(format: "%.1fK", lbs / 1_000)
        } else {
            return String(format: "%.0f", lbs)
        }
    }

}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.body.bold())
                    .foregroundStyle(accent)
                    .symbolEffect(.bounce, value: appeared)
            }
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appeared = true
            }
        }
    }
}
