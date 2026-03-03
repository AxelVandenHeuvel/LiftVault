import SwiftUI
import SwiftData

struct MovementPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Movement.name) private var movements: [Movement]
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedNames: [String] = []

    var excludedNames: Set<String> = []
    let onSelect: ([String]) -> Void

    private var categories: [String] {
        var cats = Set<String>()
        for m in movements {
            for cat in m.categoryList {
                cats.insert(cat)
            }
        }
        return ["All"] + cats.sorted()
    }

    private var filteredMovements: [Movement] {
        var result = movements
        if selectedCategory != "All" {
            result = result.filter { $0.categoryList.contains(selectedCategory) }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private var groupedByLetter: [(String, [Movement])] {
        let dict = Dictionary(grouping: filteredMovements) { movement in
            String(movement.name.prefix(1)).uppercased()
        }
        return dict.sorted { $0.key < $1.key }
    }

    private var canCreateNew: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !movements.contains {
            $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Theme.primary : Color(.systemGray5))
                                    .foregroundStyle(selectedCategory == cat ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                List {
                    if canCreateNew {
                        Section {
                            Button {
                                let name = searchText.trimmingCharacters(in: .whitespaces)
                                let movement = Movement(name: name)
                                modelContext.insert(movement)
                                toggleSelection(name)
                                searchText = ""
                            } label: {
                                Label {
                                    Text("Create \"")
                                    + Text(searchText.trimmingCharacters(in: .whitespaces)).bold()
                                    + Text("\"")
                                } icon: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                        }
                    }

                    ForEach(groupedByLetter, id: \.0) { letter, items in
                        Section(letter) {
                            ForEach(items) { movement in
                                let alreadyAdded = excludedNames.contains(movement.name)
                                let isSelected = selectedNames.contains(movement.name)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        toggleSelection(movement.name)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(movement.name)
                                            .foregroundStyle(alreadyAdded ? .tertiary : .primary)
                                            .font(.body)

                                        if alreadyAdded {
                                            Text("Added")
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(.secondary)
                                        } else if !movement.category.isEmpty {
                                            Text(movement.category)
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(Theme.accent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Theme.accent.opacity(0.2))
                                                .clipShape(Capsule())
                                        }

                                        Spacer()

                                        if !alreadyAdded {
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.title3)
                                                .foregroundStyle(isSelected ? Theme.primary : Color(.tertiaryLabel))
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .disabled(alreadyAdded)
                            }
                        }
                    }

                    if movements.isEmpty && searchText.isEmpty {
                        ContentUnavailableView(
                            "No Movements",
                            systemImage: "figure.strengthtraining.traditional",
                            description: Text("Type a name above to create your first movement.")
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search or create movement")
            .navigationTitle("Add Movements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSelect(selectedNames)
                        dismiss()
                    } label: {
                        Text("Add")
                            .bold()
                        + Text(" (\(selectedNames.count))")
                    }
                    .disabled(selectedNames.isEmpty)
                }
            }
        }
    }

    private func toggleSelection(_ name: String) {
        if let index = selectedNames.firstIndex(of: name) {
            selectedNames.remove(at: index)
        } else {
            selectedNames.append(name)
        }
    }
}
