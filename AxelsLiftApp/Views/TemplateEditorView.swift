import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Bindable var template: WorkoutTemplate
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showMovementPicker = false
    @State private var orderedExercises: [Exercise] = []
    @State private var pickedColor: Color = .blue
    @Environment(\.editMode) private var editMode

    var body: some View {
        List {
            Section {
                TextField("e.g. Push Day", text: $template.name)
                    .font(.title3.weight(.medium))
            } header: {
                Text("Template Name")
            }

            Section {
                ColorPicker("Template Color", selection: $pickedColor, supportsOpacity: false)
                    .onChange(of: pickedColor) { _, newColor in
                        template.colorName = TemplateColor.hexString(from: newColor)
                    }
            } header: {
                Text("Color")
            }

            Section {
                if template.exercises.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                                .foregroundStyle(Theme.primary.opacity(0.4))
                            Text("No movements yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    ForEach($orderedExercises) { $exercise in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(TemplateColor.color(for: template.colorName))
                                .frame(width: 8, height: 8)

                            Text(exercise.name)
                                .font(.body)
                                .lineLimit(1)

                            Spacer()

                            HStack(spacing: 6) {
                                Button {
                                    exercise.setCount = max(1, exercise.setCount - 1)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)

                                Text("\(exercise.setCount)")
                                    .font(.body.weight(.bold).monospacedDigit())
                                    .frame(width: 24, alignment: .center)

                                Button {
                                    exercise.setCount = min(10, exercise.setCount + 1)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Theme.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)
                    .tint(.red)
                }

                if editMode?.wrappedValue.isEditing != true {
                    Button {
                        showMovementPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(Theme.primary)
                                .clipShape(Circle())
                            Text("Add Movement")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.primary)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("MOVEMENTS")
                        .font(.caption.weight(.heavy))
                        .tracking(0.5)
                    Spacer()
                    if !template.exercises.isEmpty {
                        Text("\(template.exercises.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Theme.primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(template.name.isEmpty ? "New Template" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    dismiss()
                }
                .font(.body.weight(.semibold))
            }
        }
        .onAppear {
            syncOrderedExercises()
            pickedColor = TemplateColor.color(for: template.colorName)
        }
        .onDisappear {
            if template.name.trimmingCharacters(in: .whitespaces).isEmpty
                && template.exercises.isEmpty {
                modelContext.delete(template)
            }
        }
        .sheet(isPresented: $showMovementPicker) {
            MovementPickerSheet { names in
                let maxOrder = template.exercises.map(\.order).max() ?? -1
                for (i, name) in names.enumerated() {
                    let exercise = Exercise(name: name, order: maxOrder + 1 + i)
                    template.exercises.append(exercise)
                }
                syncOrderedExercises()
            }
        }
    }

    private func syncOrderedExercises() {
        orderedExercises = template.exercises.sorted { $0.order < $1.order }
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = orderedExercises[index]
            template.exercises.removeAll { $0.id == exercise.id }
            modelContext.delete(exercise)
        }
        orderedExercises.remove(atOffsets: offsets)
        for (i, ex) in orderedExercises.enumerated() {
            ex.order = i
        }
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        orderedExercises.move(fromOffsets: source, toOffset: destination)
        for (i, exercise) in orderedExercises.enumerated() {
            exercise.order = i
        }
    }
}

#Preview {
    NavigationStack {
        TemplateEditorView(
            template: WorkoutTemplate(name: "Push Day", exercises: [
                Exercise(name: "Bench Press"),
                Exercise(name: "Overhead Press"),
            ])
        )
    }
    .modelContainer(for: [WorkoutTemplate.self, Movement.self], inMemory: true)
}
