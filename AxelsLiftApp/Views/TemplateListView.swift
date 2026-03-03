import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TemplateFolder.name) private var folders: [TemplateFolder]
    @State private var newTemplate: WorkoutTemplate?
    @State private var navigateToNew = false
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var expandedFolders: Set<String> = []
    @State private var folderToDelete: TemplateFolder?

    var body: some View {
        Group {
            if folders.isEmpty {
                VStack(spacing: 16) {
                    Text("—")
                        .font(.system(size: 48, weight: .ultraLight, design: .serif))
                        .foregroundStyle(Theme.primary.opacity(0.4))

                    Text("No Folders")
                        .font(.headline)

                    Text("Tap the folder button above\nto get started.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(folders) { folder in
                        Section {
                            DisclosureGroup(
                                isExpanded: folderBinding(for: folder)
                            ) {
                                let sorted = folder.templates.sorted { $0.name < $1.name }
                                ForEach(sorted) { template in
                                    NavigationLink {
                                        TemplateEditorView(template: template)
                                    } label: {
                                        TemplateRow(template: template)
                                    }
                                    .contextMenu {
                                        let otherFolders = folders.filter { $0.id != folder.id }
                                        if !otherFolders.isEmpty {
                                            Menu {
                                                ForEach(otherFolders) { dest in
                                                    Button {
                                                        template.folder = dest
                                                    } label: {
                                                        Label(dest.name, systemImage: "folder")
                                                    }
                                                }
                                            } label: {
                                                Label("Move to…", systemImage: "folder.badge.gear")
                                            }
                                        }
                                    }
                                }
                                .onDelete { offsets in
                                    deleteTemplates(from: folder, at: offsets)
                                }
                                .tint(.red)

                                Button {
                                    let template = WorkoutTemplate(name: "")
                                    folder.templates.append(template)
                                    modelContext.insert(template)
                                    newTemplate = template
                                    navigateToNew = true
                                } label: {
                                    Label("New Template", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.primary)
                                }

                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(Theme.primary)
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(folder.name)
                                            .font(.headline)
                                        Text("\(folder.templates.count) template\(folder.templates.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    folderToDelete = folder
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .onAppear {
            if expandedFolders.isEmpty {
                for folder in folders {
                    expandedFolders.insert(folder.name)
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newFolderName = ""
                    showNewFolderAlert = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .alert("New Folder", isPresented: $showNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    modelContext.insert(TemplateFolder(name: trimmed))
                }
            }
        }
        .alert("Delete Folder?", isPresented: Binding(
            get: { folderToDelete != nil },
            set: { if !$0 { folderToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { folderToDelete = nil }
            Button("Delete", role: .destructive) {
                if let folder = folderToDelete {
                    modelContext.delete(folder)
                    folderToDelete = nil
                }
            }
        } message: {
            if let folder = folderToDelete {
                Text("This will delete \"\(folder.name)\" and all \(folder.templates.count) template\(folder.templates.count == 1 ? "" : "s") inside it.")
            }
        }
        .navigationDestination(isPresented: $navigateToNew) {
            if let newTemplate {
                TemplateEditorView(template: newTemplate)
            }
        }
    }

    private func folderBinding(for folder: TemplateFolder) -> Binding<Bool> {
        Binding(
            get: { expandedFolders.contains(folder.name) },
            set: { isExpanded in
                if isExpanded {
                    expandedFolders.insert(folder.name)
                } else {
                    expandedFolders.remove(folder.name)
                }
            }
        )
    }

    private func deleteTemplates(from folder: TemplateFolder, at offsets: IndexSet) {
        let sorted = folder.templates.sorted { $0.name < $1.name }
        for index in offsets {
            let template = sorted[index]
            modelContext.delete(template)
        }
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(TemplateColor.color(for: template.colorName))
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name.isEmpty ? "Untitled Template" : template.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(template.name.isEmpty ? .secondary : .primary)

                HStack(spacing: 6) {
                    Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !template.exercises.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(template.exercises.reduce(0) { $0 + $1.setCount }) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 12)
        }
        .padding(.vertical, 4)
    }
}
