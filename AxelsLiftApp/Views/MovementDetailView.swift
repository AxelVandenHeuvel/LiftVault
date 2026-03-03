import SwiftUI
import SwiftData
import Charts

private enum ChartRange: String, CaseIterable {
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var cutoffDate: Date? {
        let cal = Calendar.current
        switch self {
        case .month:       return cal.date(byAdding: .month, value: -1, to: Date())
        case .threeMonths: return cal.date(byAdding: .month, value: -3, to: Date())
        case .sixMonths:   return cal.date(byAdding: .month, value: -6, to: Date())
        case .year:        return cal.date(byAdding: .year, value: -1, to: Date())
        case .all:         return nil
        }
    }
}

struct MovementDetailView: View {
    let movement: Movement

    @Query private var dailyLogs: [DailyLog]
    @State private var selectedWeight: Double?
    @State private var chartRange: ChartRange = .month

    // All sets ever logged for this movement, paired with their date
    private var allEntries: [(date: Date, reps: Int, weight: Double)] {
        var result: [(Date, Int, Double)] = []
        for log in dailyLogs {
            for exercise in log.exercises where exercise.name == movement.name {
                for set in exercise.sets where set.reps > 0 && set.weight > 0 {
                    result.append((log.date, set.reps, set.weight))
                }
            }
        }
        return result
    }

    // Unique weights sorted ascending
    private var availableWeights: [Double] {
        Array(Set(allEntries.map(\.weight))).sorted()
    }

    // Weight PR: heaviest weight ever (with best reps at that weight)
    private var weightPR: (weight: Double, reps: Int, date: Date)? {
        guard !allEntries.isEmpty else { return nil }
        let maxWeight = allEntries.map(\.weight).max()!
        let atMax = allEntries.filter { $0.weight == maxWeight }
        guard let best = atMax.max(by: { $0.reps < $1.reps }) else { return nil }
        return (best.weight, best.reps, best.date)
    }

    // Rep PR at selected weight: most reps ever at that weight
    private var repPR: (reps: Int, date: Date)? {
        guard let weight = selectedWeight else { return nil }
        let atWeight = allEntries.filter { $0.weight == weight }
        guard let best = atWeight.max(by: { $0.reps < $1.reps }) else { return nil }
        return (best.reps, best.date)
    }

    // Chart data: for each day at the selected weight, take max reps (filtered by range)
    private var chartData: [(label: String, reps: Int)] {
        guard let weight = selectedWeight else { return [] }
        let cutoff = chartRange.cutoffDate
        let filtered = allEntries.filter { entry in
            entry.weight == weight && (cutoff == nil || entry.date >= cutoff!)
        }

        var bestByDay: [Date: Int] = [:]
        for entry in filtered {
            let day = Calendar.current.startOfDay(for: entry.date)
            bestByDay[day] = max(bestByDay[day] ?? 0, entry.reps)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return bestByDay
            .sorted { $0.key < $1.key }
            .map { (label: formatter.string(from: $0.key), reps: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category badges
                HStack(spacing: 8) {
                    ForEach(movement.categoryList, id: \.self) { cat in
                        Text(cat)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(colorForCategory(cat))
                            .clipShape(Capsule())
                    }
                }

                // MARK: - Personal Records / Empty State
                if allEntries.isEmpty {
                    VStack(spacing: 16) {
                        Text("—")
                            .font(.system(size: 48, weight: .ultraLight, design: .serif))
                            .foregroundStyle(Theme.primary.opacity(0.4))

                        Text("No data yet")
                            .font(.headline)

                        Text("Start logging sets for this movement\nto see your charts and PRs here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.primary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }

                if !allEntries.isEmpty {
                    VStack(spacing: 10) {
                        if let pr = weightPR {
                            HStack(spacing: 10) {
                                Image(systemName: "crown.fill")
                                    .font(.title3)
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("WEIGHT PR")
                                        .font(.caption2.weight(.heavy))
                                        .tracking(1)
                                        .foregroundStyle(.secondary)
                                    Text("\(pr.weight, specifier: "%g") lbs × \(pr.reps) reps")
                                        .font(.subheadline.weight(.bold))
                                }
                                Spacer()
                                Text(shortDate(pr.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        if let pr = repPR, let weight = selectedWeight {
                            HStack(spacing: 10) {
                                Image(systemName: "flame.fill")
                                    .font(.title3)
                                    .foregroundStyle(Theme.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("REP PR AT \(weight, specifier: "%g") LBS")
                                        .font(.caption2.weight(.heavy))
                                        .tracking(1)
                                        .foregroundStyle(.secondary)
                                    Text("\(pr.reps) reps")
                                        .font(.subheadline.weight(.bold))
                                }
                                Spacer()
                                Text(shortDate(pr.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: - Reps Over Time Chart
                if !availableWeights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REPS OVER TIME")
                            .font(.caption.weight(.heavy))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        // Weight dropdown
                        Menu {
                            ForEach(availableWeights, id: \.self) { weight in
                                Button {
                                    selectedWeight = weight
                                } label: {
                                    if selectedWeight == weight {
                                        Label("\(weight, specifier: "%g") lbs", systemImage: "checkmark")
                                    } else {
                                        Text("\(weight, specifier: "%g") lbs")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedWeight != nil ? "\(selectedWeight!, specifier: "%g") lbs" : "Select Weight")
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }

                        Picker("Range", selection: $chartRange) {
                            ForEach(ChartRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)

                        if selectedWeight != nil, !chartData.isEmpty {
                            Chart(chartData, id: \.label) { point in
                                LineMark(
                                    x: .value("Date", point.label),
                                    y: .value("Reps", point.reps)
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(Theme.accent)

                                PointMark(
                                    x: .value("Date", point.label),
                                    y: .value("Reps", point.reps)
                                )
                                .foregroundStyle(Theme.accent)
                                .symbolSize(40)

                                AreaMark(
                                    x: .value("Date", point.label),
                                    y: .value("Reps", point.reps)
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(Theme.accent.opacity(0.15))
                            }
                            .chartYAxisLabel("Reps")
                            .chartYScale(domain: 0...(Double(chartData.map(\.reps).max() ?? 1) * 1.2))
                            .frame(height: 200)
                            .padding(.top, 4)

                            // Summary row
                            HStack(spacing: 12) {
                                statBubble(
                                    label: "Best",
                                    value: "\(chartData.map(\.reps).max() ?? 0) reps"
                                )
                                statBubble(
                                    label: "Sessions",
                                    value: "\(chartData.count)"
                                )
                                if chartData.count >= 2,
                                   let first = chartData.first,
                                   let last = chartData.last {
                                    let trend = last.reps - first.reps
                                    statBubble(
                                        label: "Trend",
                                        value: "\(trend > 0 ? "+" : "")\(trend) reps"
                                    )
                                }
                            }
                            .padding(.top, 4)
                        } else if selectedWeight != nil {
                            Text("No data at this weight yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            Text("Select a weight to view your reps over time.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle(movement.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Auto-select the most recently used weight
            if selectedWeight == nil, let mostRecent = allEntries.sorted(by: { $0.date > $1.date }).first {
                selectedWeight = mostRecent.weight
            }
        }
    }

    // MARK: - Helpers

    private func shortDate(_ d: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: d)
    }

    private func statBubble(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Chest":      return .red
        case "Back":       return .blue
        case "Shoulders":  return .orange
        case "Quads":      return .green
        case "Hamstrings": return .mint
        case "Glutes":     return .pink
        case "Calves":     return .teal
        case "Biceps":     return .purple
        case "Triceps":    return .indigo
        case "Forearms":   return .brown
        case "Core":       return .yellow
        default:           return .gray
        }
    }
}
