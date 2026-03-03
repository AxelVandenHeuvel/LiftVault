import SwiftUI
import SwiftData

struct MovementLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Movement.name) private var movements: [Movement]

    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingAddSheet = false
    @State private var movementToDelete: Movement?
    @State private var showFirstWarning = false
    @State private var showSecondWarning = false

    private let categories = ["All", "Chest", "Back", "Shoulders", "Quads", "Hamstrings", "Glutes", "Calves", "Biceps", "Triceps", "Forearms", "Core"]

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

    var body: some View {
        List {
            ForEach(groupedByLetter, id: \.0) { letter, items in
                Section {
                    ForEach(items) { movement in
                        NavigationLink {
                            MovementDetailView(movement: movement)
                        } label: {
                            HStack(spacing: 12) {
                                Text(movement.name)
                                    .font(.body)

                                Spacer()

                                if let firstCat = movement.categoryList.first {
                                    Text(firstCat)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(Theme.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Theme.accent.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(minHeight: 44)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                movementToDelete = movement
                                showFirstWarning = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                } header: {
                    Text(letter)
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                        .foregroundStyle(Theme.primary)
                }
            }

            if filteredMovements.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Text("—")
                            .font(.system(size: 36, weight: .ultraLight, design: .serif))
                            .foregroundStyle(Theme.primary.opacity(0.4))
                        Text("No movements found")
                            .font(.subheadline.weight(.medium))
                        Text("Try a different search or filter.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Movements")
        .searchable(text: $searchText, prompt: "Search movements")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedCategory)
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMovementSheet()
        }
        .alert("Delete Movement?", isPresented: $showFirstWarning) {
            Button("Cancel", role: .cancel) { movementToDelete = nil }
            Button("Delete", role: .destructive) {
                showSecondWarning = true
            }
        } message: {
            Text("Deleting \"\(movementToDelete?.name ?? "")\" will permanently erase all logged data for this movement across every workout.")
        }
        .alert("Are you sure?", isPresented: $showSecondWarning) {
            Button("Cancel", role: .cancel) { movementToDelete = nil }
            Button("Delete Forever", role: .destructive) {
                if let movement = movementToDelete {
                    modelContext.delete(movement)
                    movementToDelete = nil
                }
            }
        } message: {
            Text("This cannot be undone. All history for \"\(movementToDelete?.name ?? "")\" will be lost.")
        }
    }
}

// MARK: - Add Movement Sheet

private struct AddMovementSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedCategories: Set<String> = []

    private let categories = ["Chest", "Back", "Shoulders", "Quads", "Hamstrings", "Glutes", "Calves", "Biceps", "Triceps", "Forearms", "Core"]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Movement Name") {
                    TextField("e.g. Incline Dumbbell Press", text: $name)
                }

                Section("Categories") {
                    FlowLayout(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                if selectedCategories.contains(cat) {
                                    selectedCategories.remove(cat)
                                } else {
                                    selectedCategories.insert(cat)
                                }
                            } label: {
                                Text(cat)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(selectedCategories.contains(cat) ? Theme.primary : Color(.systemGray5))
                                    .foregroundStyle(selectedCategories.contains(cat) ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
            }
            .navigationTitle("New Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let cats = categories.filter { selectedCategories.contains($0) }.joined(separator: ", ")
                        let movement = Movement(name: trimmedName, category: cats.isEmpty ? "Other" : cats)
                        modelContext.insert(movement)
                        dismiss()
                    }
                    .bold()
                    .disabled(trimmedName.isEmpty || selectedCategories.isEmpty)
                }
            }
        }
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(x: bounds.minX + result.positions[index].x,
                                y: bounds.minY + result.positions[index].y)
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
