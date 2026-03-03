import SwiftUI
import SwiftData
import ActivityKit
import UserNotifications

enum DayDetailSheet: Identifiable {
    case template
    case movement
    case addSet(LogExercise)
    case editSet(LogSet)
    case aiInput

    var id: String {
        switch self {
        case .template: return "template"
        case .movement: return "movement"
        case .addSet(let e): return "add-\(e.id)"
        case .editSet(let s): return "edit-\(s.id)"
        case .aiInput: return "aiInput"
        }
    }
}

struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var dailyLogs: [DailyLog]
    @Query private var movements: [Movement]
    @State private var activeSheet: DayDetailSheet?
    @State private var barVisible = false
    @State private var timerEndDate: Date?
    @State private var timerExerciseID: PersistentIdentifier?
    @AppStorage("restDuration") private var restDuration: Double = 90
    @AppStorage("timerEnabled") private var timerEnabled = true
    @State private var showTimerPicker = false
    @State private var pickerMinutes = 1
    @State private var pickerSeconds = 30
    @State private var currentActivity: Activity<RestTimerAttributes>?
    @FocusState private var notesFocused: Bool
    @State private var keyboardVisible = false
    @State private var showClearConfirm = false

    private var log: DailyLog? {
        dailyLogs.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)

    private var isFutureDate: Bool {
        date > Calendar.current.startOfDay(for: Date()).addingTimeInterval(86399)
    }

    private var previousTemplateLog: DailyLog? {
        guard let name = log?.templateName, !name.isEmpty else { return nil }
        return dailyLogs
            .filter { $0.templateName == name && !Calendar.current.isDate($0.date, inSameDayAs: date) && $0.date < date }
            .sorted { $0.date > $1.date }
            .first
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                if !isFutureDate {
                    timerSettingsSection
                }

                if let prevLog = previousTemplateLog {
                    Section {
                        NavigationLink(value: prevLog.date) {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Last \(log?.templateName ?? "Workout")")
                                        .font(.subheadline.weight(.semibold))
                                    Text(shortDate(prevLog.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .frame(minHeight: 44)
                        }
                    }
                }

                if let log, !log.exercises.isEmpty {
                    let sorted = sortedExercises(log)
                    let exerciseCount = sorted.count
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, exercise in
                        exerciseSection(log: log, exercise: exercise, index: index, total: exerciseCount)
                    }

                    // Workout timer + finish button
                    workoutTimerSection(log: log)

                    // Workout notes
                    notesSection

                    // Extra space so content is not hidden behind floating bar
                    Section {} footer: {
                        Spacer().frame(height: 72)
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.primary.opacity(0.5))

                            Text("Rest day?")
                                .font(.headline)

                            Text("Add movements or apply a template\nto start logging.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    .listRowBackground(Color.clear)
                }
            }

            // Bottom floating action bar (today or past only)
            if !isFutureDate {
            HStack(spacing: 10) {
                Button {
                    hapticMedium.impactOccurred()
                    activeSheet = .movement
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.subheadline.bold())
                        Text("Movement")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Theme.primary.opacity(0.25), radius: 6, y: 3)
                }

                Button {
                    hapticMedium.impactOccurred()
                    activeSheet = .template
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline.bold())
                        Text("Template")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray4))
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .offset(y: barVisible && !keyboardVisible ? 0 : 60)
            .opacity(barVisible && !keyboardVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: keyboardVisible)
            } // end if !isFutureDate
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                barVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
        .navigationTitle(formattedDate)
        .toolbar {
            if !isFutureDate {
                ToolbarItem(placement: .topBarLeading) {
                    if log != nil && !(log?.exercises.isEmpty ?? true) {
                        ShareLink(item: workoutSummary ?? "") {
                            Image(systemName: "square.and.arrow.up")
                                .offset(y: -1)
                        }
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if log != nil && !(log?.exercises.isEmpty ?? true) {
                        Button {
                            showClearConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    EditButton()
                    if #available(iOS 26, *) {
                        Button {
                            activeSheet = .aiInput
                        } label: {
                            Image(systemName: "sparkles")
                        }
                    }
                }
            }
        }
        .alert("Clear Workout?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                if let log {
                    for exercise in log.exercises {
                        modelContext.delete(exercise)
                    }
                    log.exercises.removeAll()
                    log.templateName = nil
                    log.templateColorName = nil
                    log.startTime = nil
                    log.endTime = nil
                    log.isFinished = false
                    log.wasTimedOut = false
                }
            }
        } message: {
            Text("This will remove all exercises and sets from this day.")
        }
        .onChange(of: timerEnabled) { _, enabled in
            if !enabled {
                timerEndDate = nil
                showTimerPicker = false
            }
        }
        .onChange(of: timerEndDate) { _, newValue in
            if let endDate = newValue {
                startLiveActivity(endDate: endDate)
                let delay = endDate.timeIntervalSinceNow
                if delay > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if let current = timerEndDate, current == endDate {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            endLiveActivity()
                        }
                    }
                }
            } else {
                endLiveActivity()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .template:
                TemplatePickerSheet(date: date, existingLog: log)
            case .movement:
                MovementPickerSheet(excludedNames: Set(log?.exercises.map(\.name) ?? [])) { names in
                    hapticLight.impactOccurred()
                    for name in names {
                        addMovement(named: name)
                    }
                }
            case .addSet(let exercise):
                AddSetSheet(
                    exerciseName: exercise.name,
                    lastReps: lastRepsForSheet(exercise),
                    lastWeight: lastWeightForSheet(exercise)
                ) { reps, weight in
                    hapticMedium.impactOccurred()
                    exercise.sets.append(LogSet(reps: reps, weight: weight))
                    log?.stampSetLogged()
                    if timerEnabled {
                        timerExerciseID = exercise.persistentModelID
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            timerEndDate = Date().addingTimeInterval(restDuration)
                        }
                    }
                }
            case .editSet(let logSet):
                let name = logSet.logExercise?.name ?? ""
                let history = lastLoggedSet(for: name)
                EditSetSheet(logSet: logSet, fallbackReps: history.reps, fallbackWeight: history.weight) {
                    log?.stampSetLogged()
                    if timerEnabled {
                        timerExerciseID = logSet.logExercise?.persistentModelID
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            timerEndDate = Date().addingTimeInterval(restDuration)
                        }
                    }
                }
            case .aiInput:
                if #available(iOS 26, *) {
                    WorkoutInputSheet(date: date, existingLog: log, movements: movements)
                } else {
                    Text("Requires iOS 26 or later")
                }
            }
        }
    }

    private func addMovement(named name: String) {
        let currentLog: DailyLog
        if let existing = log {
            currentLog = existing
        } else {
            currentLog = DailyLog(date: date)
            modelContext.insert(currentLog)
        }
        let maxOrder = currentLog.exercises.map(\.order).max() ?? -1
        let exercise = LogExercise(name: name, order: maxOrder + 1)
        currentLog.exercises.append(exercise)
    }

    private func lastRepsForSheet(_ exercise: LogExercise) -> Int {
        if let last = exercise.sets.last, last.reps > 0 { return last.reps }
        return lastLoggedSet(for: exercise.name).reps
    }

    private func lastWeightForSheet(_ exercise: LogExercise) -> Double {
        if let last = exercise.sets.last, last.weight > 0 { return last.weight }
        return lastLoggedSet(for: exercise.name).weight
    }

    /// Finds the most recent non-zero set for a movement name across all logs (including today).
    /// Returns the last set with actual values, preferring more recent dates.
    private func lastLoggedSet(for name: String) -> (reps: Int, weight: Double) {
        guard !name.isEmpty else { return (0, 0) }
        var bestDate: Date = .distantPast
        var bestReps = 0
        var bestWeight = 0.0
        for log in dailyLogs {
            for exercise in log.exercises where exercise.name == name {
                for set in exercise.sets where set.reps > 0 && set.weight > 0 {
                    if log.date > bestDate || (log.date == bestDate && true) {
                        bestDate = log.date
                        bestReps = set.reps
                        bestWeight = set.weight
                    }
                }
            }
        }
        return (bestReps, bestWeight)
    }

    private func sortedExercises(_ log: DailyLog) -> [LogExercise] {
        log.exercises.sorted { $0.order < $1.order }
    }

    /// Computes PR data for a given exercise name across all logs.
    /// Returns (maxWeight, maxRepsPerWeight) so each set can check if it's a PR.
    private func computePRs(for name: String) -> (maxWeight: Double, maxRepsPerWeight: [Double: Int]) {
        var maxWeight: Double = 0
        var maxRepsPerWeight: [Double: Int] = [:]

        for log in dailyLogs {
            for exercise in log.exercises where exercise.name == name {
                for set in exercise.sets where set.reps > 0 && set.weight > 0 {
                    maxWeight = max(maxWeight, set.weight)
                    maxRepsPerWeight[set.weight] = max(maxRepsPerWeight[set.weight] ?? 0, set.reps)
                }
            }
        }

        return (maxWeight, maxRepsPerWeight)
    }

    private func deleteExercises(from log: DailyLog, sorted: [LogExercise], at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            let exercise = sorted[index]
            log.exercises.removeAll { $0.id == exercise.id }
            modelContext.delete(exercise)
        }
        for (i, ex) in log.exercises.sorted(by: { $0.order < $1.order }).enumerated() {
            ex.order = i
        }
    }

    private func swapExerciseOrder(in log: DailyLog, index: Int, with otherIndex: Int) {
        let sorted = sortedExercises(log)
        guard sorted.indices.contains(index), sorted.indices.contains(otherIndex) else { return }
        let temp = sorted[index].order
        sorted[index].order = sorted[otherIndex].order
        sorted[otherIndex].order = temp
        hapticLight.impactOccurred()
    }

    @ViewBuilder
    private func exerciseSection(log: DailyLog, exercise: LogExercise, index: Int, total: Int) -> some View {
        let prs = computePRs(for: exercise.name)
        let matchedMovement: Movement? = movements.first { $0.name == exercise.name }
        LogExerciseSection(exercise: exercise, onSheet: { sheet in
            activeSheet = sheet
        }, onSetAdded: {
            log.stampSetLogged()
            guard timerEnabled else { return }
            timerExerciseID = exercise.persistentModelID
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                timerEndDate = Date().addingTimeInterval(restDuration)
            }
        }, timerEndDate: $timerEndDate,
           timerExerciseID: timerExerciseID,
           restDuration: restDuration,
           movement: matchedMovement,
           prMaxWeight: prs.maxWeight,
           prMaxRepsPerWeight: prs.maxRepsPerWeight,
           onRemoveExercise: {
               log.exercises.removeAll { $0.id == exercise.id }
               modelContext.delete(exercise)
           },
           onMoveUp: {
               swapExerciseOrder(in: log, index: index, with: index - 1)
           },
           onMoveDown: {
               swapExerciseOrder(in: log, index: index, with: index + 1)
           },
           isFirst: index == 0,
           isLast: index == total - 1)
    }

    private var timerSettingsSection: some View {
        Section {
            HStack {
                Image(systemName: "timer")
                    .font(.subheadline)
                    .foregroundStyle(timerEnabled ? Theme.accent : .secondary)

                Text("Rest Timer")
                    .font(.subheadline)

                Spacer()

                if timerEnabled {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if !showTimerPicker {
                                pickerMinutes = Int(restDuration) / 60
                                pickerSeconds = Int(restDuration) % 60
                            }
                            showTimerPicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(formatDuration(restDuration))
                                .font(.subheadline.weight(.medium).monospacedDigit())
                            Image(systemName: showTimerPicker ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                }

                Toggle("", isOn: $timerEnabled)
                    .labelsHidden()
            }

            if showTimerPicker && timerEnabled {
                HStack(spacing: 0) {
                    Picker("Minutes", selection: $pickerMinutes) {
                        ForEach(0...5, id: \.self) { m in
                            Text("\(m) min").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()

                    Picker("Seconds", selection: $pickerSeconds) {
                        ForEach([0, 15, 30, 45], id: \.self) { s in
                            Text("\(s) sec").tag(s)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .onChange(of: pickerMinutes) { _, _ in applyPickerDuration() }
                .onChange(of: pickerSeconds) { _, _ in applyPickerDuration() }
            }
        }
    }

    @ViewBuilder
    private func workoutTimerSection(log: DailyLog) -> some View {
        if let start = log.startTime {
            Section {
                if log.isFinished {
                    // Finished — show static duration + resume option
                    if let dur = log.duration, dur > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: log.wasTimedOut ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(log.wasTimedOut ? .orange : .green)
                            Text(log.wasTimedOut ? "Timed Out (5h limit)" : "Workout Complete")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(formatWorkoutDuration(dur))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            hapticLight.impactOccurred()
                            log.isFinished = false
                            log.wasTimedOut = false
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption.bold())
                                Text("Continue Workout")
                                    .font(.subheadline.weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(Theme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // Active — live counting timer
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let elapsed = context.date.timeIntervalSince(start)
                        let timedOut = elapsed >= DailyLog.maxDuration

                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.accent)
                                Text("Duration")
                                    .font(.subheadline)
                                Spacer()
                                Text(formatLiveTimer(elapsed))
                                    .font(.title3.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Theme.primary)
                            }

                            Button {
                                hapticMedium.impactOccurred()
                                log.finishWorkout()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "flag.checkered")
                                        .font(.subheadline.bold())
                                    Text("Finish Workout")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .onChange(of: timedOut) { _, isTimedOut in
                            if isTimedOut && !log.isFinished {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                log.wasTimedOut = true
                                log.finishWorkout()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if let log {
            Section {
                TextField("Add workout notes...", text: Binding(
                    get: { log.notes },
                    set: { log.notes = $0 }
                ), axis: .vertical)
                .lineLimit(2...6)
                .font(.subheadline)
                .focused($notesFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            notesFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            } header: {
                Text("NOTES")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var workoutSummary: String? {
        guard let log, !log.exercises.isEmpty else { return nil }
        var lines: [String] = []

        lines.append("LiftVault — \(formattedDate)")
        if let template = log.templateName, !template.isEmpty {
            lines.append(template)
        }
        lines.append("")

        for exercise in sortedExercises(log) {
            lines.append(exercise.name)
            for (i, set) in exercise.sets.enumerated() {
                let w = set.weight.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", set.weight)
                    : "\(set.weight)"
                lines.append("  Set \(i + 1): \(set.reps) reps × \(w) lbs")
            }
            lines.append("")
        }

        if let dur = log.duration, dur > 0 {
            lines.append("Duration: \(formatWorkoutDuration(dur))")
        }

        if !log.notes.isEmpty {
            lines.append("Notes: \(log.notes)")
        }

        return lines.joined(separator: "\n")
    }

    private func shortDate(_ d: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: d)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatWorkoutDuration(_ seconds: TimeInterval) -> String {
        let totalMins = Int(seconds) / 60
        if totalMins < 60 {
            return "\(totalMins)m"
        }
        let hrs = totalMins / 60
        let mins = totalMins % 60
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }

    private func formatLiveTimer(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%d:%02d", mins, secs)
    }

    private func applyPickerDuration() {
        let total = Double(pickerMinutes * 60 + pickerSeconds)
        let clamped = max(15, min(300, total))
        restDuration = clamped
        if timerEndDate != nil {
            timerEndDate = Date().addingTimeInterval(clamped)
        }
    }

    private func startLiveActivity(endDate: Date) {
        endLiveActivity()
        let attributes = RestTimerAttributes(duration: restDuration)
        let state = RestTimerAttributes.ContentState(timerEnd: endDate)
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate),
                pushType: nil
            )
        } catch {
            // Live Activities may not be available
        }
        scheduleTimerNotification(endDate: endDate)
    }

    private func endLiveActivity() {
        cancelTimerNotification()
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    private func scheduleTimerNotification(endDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        center.removePendingNotificationRequests(withIdentifiers: ["restTimer"])

        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Done"
        content.body = "Time to start your next set!"
        content.sound = .default

        let delay = max(1, endDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelTimerNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }
}

// MARK: - Exercise Section (name + list of sets)

private struct LogExerciseSection: View {
    @Bindable var exercise: LogExercise
    @Environment(\.modelContext) private var modelContext
    let onSheet: (DayDetailSheet) -> Void
    let onSetAdded: () -> Void
    @Binding var timerEndDate: Date?
    let timerExerciseID: PersistentIdentifier?
    let restDuration: Double
    var movement: Movement?
    var prMaxWeight: Double = 0
    var prMaxRepsPerWeight: [Double: Int] = [:]
    var onRemoveExercise: (() -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var isFirst: Bool = true
    var isLast: Bool = true

    @Environment(\.editMode) private var editMode
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        Section {
            setsContent
            timerContent
            addSetButton
        } header: {
            sectionHeader
        }
    }

    @ViewBuilder
    private var setsContent: some View {
        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, logSet in
            Button {
                onSheet(.editSet(logSet))
            } label: {
                setRowLabel(index: index, logSet: logSet)
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .leading) {
                Button {
                    hapticLight.impactOccurred()
                    // Fill an empty template set first, otherwise append
                    if let empty = exercise.sets.first(where: { $0.reps == 0 && $0.weight == 0 }) {
                        empty.reps = logSet.reps
                        empty.weight = logSet.weight
                    } else {
                        exercise.sets.append(LogSet(reps: logSet.reps, weight: logSet.weight))
                    }
                    onSetAdded()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                .tint(Theme.accent)
            }
        }
        .onDelete(perform: deleteSets)
        .tint(.red)
    }

    private func setRowLabel(index: Int, logSet: LogSet) -> some View {
        HStack(spacing: 14) {
            Text("Set \(index + 1)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            Text("\(logSet.reps)")
                .font(.body.weight(.semibold))
                .monospacedDigit()
            + Text(" reps")
                .font(.body)
                .foregroundColor(.secondary)

            Text("\(logSet.weight, specifier: "%g")")
                .font(.body.weight(.semibold))
                .monospacedDigit()
            + Text(" lbs")
                .font(.body)
                .foregroundColor(.secondary)

            if logSet.weight > 0 && logSet.reps > 0 {
                if logSet.weight >= prMaxWeight && prMaxWeight > 0 {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                if let bestReps = prMaxRepsPerWeight[logSet.weight],
                   logSet.reps >= bestReps && bestReps > 0 {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.primary)
                }
            }

            Spacer()

            Image(systemName: "pencil")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .frame(minHeight: 48)
    }

    @ViewBuilder
    private var timerContent: some View {
        if !exercise.sets.isEmpty, let endDate = timerEndDate, exercise.persistentModelID == timerExerciseID {
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                let remaining = max(0, endDate.timeIntervalSince(context.date))
                let progress = 1.0 - (remaining / restDuration)
                let isDone = remaining == 0

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(isDone ? Color.green : Theme.accent,
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: isDone ? "checkmark" : "timer")
                            .font(.caption2.bold())
                            .foregroundStyle(isDone ? .green : Theme.accent)
                    }
                    .frame(width: 26, height: 26)

                    Text(isDone ? "Rest Done!" : formatTime(remaining))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isDone ? .green : .primary)

                    Spacer()

                    Button {
                        withAnimation { timerEndDate = nil }
                    } label: {
                        Text("Skip")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowBackground(Color(.systemGray6).opacity(0.3))
        }
    }

    @ViewBuilder
    private var addSetButton: some View {
        if !isEditing {
            Button {
                onSheet(.addSet(exercise))
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Theme.primary)
                        .clipShape(Circle())
                    Text("Add Set")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.primary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            if isEditing {
                Button {
                    onRemoveExercise?()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                }
            }

            Text(exercise.name.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1)
                .foregroundStyle(.primary)
                .textCase(nil)

            Spacer()

            if isEditing {
                moveButtons
            } else if let movement {
                NavigationLink {
                    MovementDetailView(movement: movement)
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
        }
    }

    private var moveButtons: some View {
        HStack(spacing: 12) {
            Button {
                onMoveUp?()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .foregroundStyle(isFirst ? Color.gray.opacity(0.3) : Theme.primary)
            }
            .disabled(isFirst)

            Button {
                onMoveDown?()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(isLast ? Color.gray.opacity(0.3) : Theme.primary)
            }
            .disabled(isLast)
        }
    }

    private func deleteSets(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            let set = exercise.sets.remove(at: index)
            modelContext.delete(set)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Edit Set Sheet

private struct EditSetSheet: View {
    @Bindable var logSet: LogSet
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReps: Int
    @State private var selectedWeight: Double
    @State private var repsText: String
    @State private var weightText: String
    @State private var repsPage: Int
    @State private var weightPage: Int
    @State private var showPlateCalc = false
    @FocusState private var repsFieldFocused: Bool
    @FocusState private var weightFieldFocused: Bool

    private static let repsPageLabels = ["1–15", "16–30"]
    private let repsPages: [[Int]] = [
        Array(1...15),
        Array(16...30),
    ]

    private static let weightPageLabels = [
        "5–75", "80–150", "155–225", "230–300", "305–375", "380–450", "455–500"
    ]
    private let weightPages: [[Int]] = [
        stride(from: 5, through: 75, by: 5).map { $0 },
        stride(from: 80, through: 150, by: 5).map { $0 },
        stride(from: 155, through: 225, by: 5).map { $0 },
        stride(from: 230, through: 300, by: 5).map { $0 },
        stride(from: 305, through: 375, by: 5).map { $0 },
        stride(from: 380, through: 450, by: 5).map { $0 },
        stride(from: 455, through: 500, by: 5).map { $0 },
    ]

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 5)

    init(logSet: LogSet, fallbackReps: Int = 0, fallbackWeight: Double = 0, onSave: (() -> Void)? = nil) {
        self.logSet = logSet
        self.onSave = onSave
        let reps = logSet.reps > 0 ? logSet.reps : fallbackReps
        let weight = logSet.weight > 0 ? logSet.weight : fallbackWeight
        _selectedReps = State(initialValue: reps)
        _selectedWeight = State(initialValue: weight)
        _repsText = State(initialValue: reps > 0 ? "\(reps)" : "")
        _weightText = State(initialValue: weight > 0 ? "\(weight.formatted(.number.grouping(.never)))" : "")
        _repsPage = State(initialValue: reps > 15 ? 1 : 0)

        let w = Int(weight)
        var tab = 0
        if w >= 455 { tab = 6 }
        else if w >= 380 { tab = 5 }
        else if w >= 305 { tab = 4 }
        else if w >= 230 { tab = 3 }
        else if w >= 155 { tab = 2 }
        else if w >= 80 { tab = 1 }
        _weightPage = State(initialValue: tab)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Reps")
                            .font(.title3.bold())
                        Spacer()
                        TextField("0", text: $repsText)
                            .keyboardType(.numberPad)
                            .focused($repsFieldFocused)
                            .multilineTextAlignment(.center)
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(Theme.primary)
                            .frame(width: 70)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onChange(of: repsFieldFocused) { _, focused in
                                if focused { repsText = "" }
                            }
                            .onChange(of: repsText) { _, newValue in
                                if let val = Int(newValue) {
                                    selectedReps = val
                                } else if newValue.isEmpty {
                                    selectedReps = 0
                                }
                            }
                    }
                    .padding(.horizontal)

                    PageIndicator(
                        labels: Self.repsPageLabels,
                        currentPage: repsPage
                    )

                    TabView(selection: $repsPage) {
                        ForEach(Array(repsPages.enumerated()), id: \.offset) { i, values in
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(values, id: \.self) { value in
                                    NumberButton(
                                        value: value,
                                        isSelected: selectedReps == value
                                    ) {
                                        selectedReps = value
                                        repsText = "\(value)"
                                        repsFieldFocused = false
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 250)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Weight (lbs)")
                            .font(.title3.bold())

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showPlateCalc.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showPlateCalc ? "xmark" : "plus.forwardslash.minus")
                                    .font(.caption2.bold())
                                if !showPlateCalc {
                                    Text("Plates")
                                        .font(.caption2.weight(.bold))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(showPlateCalc ? Color(.systemGray5) : Theme.primary.opacity(0.12))
                            .foregroundStyle(showPlateCalc ? .secondary : Theme.primary)
                            .clipShape(Capsule())
                        }

                        Spacer()
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .focused($weightFieldFocused)
                            .multilineTextAlignment(.center)
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(Theme.primary)
                            .frame(width: 70)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onChange(of: weightFieldFocused) { _, focused in
                                if focused { weightText = "" }
                            }
                            .onChange(of: weightText) { _, newValue in
                                if let val = Double(newValue) {
                                    selectedWeight = val
                                } else if newValue.isEmpty {
                                    selectedWeight = 0
                                }
                            }
                    }
                    .padding(.horizontal)

                    if showPlateCalc {
                        PlateCalculator(weight: $selectedWeight, weightText: $weightText)
                    }

                    PageIndicator(
                        labels: Self.weightPageLabels,
                        currentPage: weightPage
                    )

                    TabView(selection: $weightPage) {
                        ForEach(Array(weightPages.enumerated()), id: \.offset) { i, values in
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(values, id: \.self) { value in
                                    NumberButton(
                                        value: value,
                                        isSelected: Int(selectedWeight) == value
                                    ) {
                                        selectedWeight = Double(value)
                                        weightText = "\(value)"
                                        weightFieldFocused = false
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 250)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle(logSet.logExercise?.name ?? "Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        logSet.reps = max(1, selectedReps)
                        logSet.weight = max(0, selectedWeight)
                        onSave?()
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        repsFieldFocused = false
                        weightFieldFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}

// MARK: - Add Set Sheet

private struct AddSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReps: Int
    @State private var selectedWeight: Double
    @State private var repsText: String
    @State private var weightText: String
    @State private var repsPage: Int
    @State private var weightPage: Int
    @State private var showPlateCalc = false
    @FocusState private var repsFieldFocused: Bool
    @FocusState private var weightFieldFocused: Bool

    let exerciseName: String
    let onAdd: (Int, Double) -> Void

    private static let repsPageLabels = ["1–15", "16–30"]
    private let repsPages: [[Int]] = [
        Array(1...15),
        Array(16...30),
    ]

    private static let weightPageLabels = [
        "5–75", "80–150", "155–225", "230–300", "305–375", "380–450", "455–500"
    ]
    private let weightPages: [[Int]] = [
        stride(from: 5, through: 75, by: 5).map { $0 },
        stride(from: 80, through: 150, by: 5).map { $0 },
        stride(from: 155, through: 225, by: 5).map { $0 },
        stride(from: 230, through: 300, by: 5).map { $0 },
        stride(from: 305, through: 375, by: 5).map { $0 },
        stride(from: 380, through: 450, by: 5).map { $0 },
        stride(from: 455, through: 500, by: 5).map { $0 },
    ]

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 5)

    init(exerciseName: String, lastReps: Int, lastWeight: Double, onAdd: @escaping (Int, Double) -> Void) {
        self.exerciseName = exerciseName
        self.onAdd = onAdd
        let reps = lastReps > 0 ? lastReps : 0
        let weight = lastWeight > 0 ? lastWeight : 0.0
        _selectedReps = State(initialValue: reps)
        _selectedWeight = State(initialValue: weight)
        _repsText = State(initialValue: reps > 0 ? "\(reps)" : "")
        _weightText = State(initialValue: weight > 0 ? "\(weight.formatted(.number.grouping(.never)))" : "")
        _repsPage = State(initialValue: reps > 15 ? 1 : 0)

        var tab = 0
        if weight >= 455 { tab = 6 }
        else if weight >= 380 { tab = 5 }
        else if weight >= 305 { tab = 4 }
        else if weight >= 230 { tab = 3 }
        else if weight >= 155 { tab = 2 }
        else if weight >= 80 { tab = 1 }
        _weightPage = State(initialValue: tab)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // MARK: Reps
                VStack(spacing: 8) {
                    HStack {
                        Text("Reps")
                            .font(.title3.bold())
                        Spacer()
                        TextField("0", text: $repsText)
                            .keyboardType(.numberPad)
                            .focused($repsFieldFocused)
                            .multilineTextAlignment(.center)
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(Theme.primary)
                            .frame(width: 70)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onChange(of: repsFieldFocused) { _, focused in
                                if focused { repsText = "" }
                            }
                            .onChange(of: repsText) { _, newValue in
                                if let val = Int(newValue) {
                                    selectedReps = val
                                } else if newValue.isEmpty {
                                    selectedReps = 0
                                }
                            }
                    }
                    .padding(.horizontal)

                    PageIndicator(
                        labels: Self.repsPageLabels,
                        currentPage: repsPage
                    )

                    TabView(selection: $repsPage) {
                        ForEach(Array(repsPages.enumerated()), id: \.offset) { i, values in
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(values, id: \.self) { value in
                                    NumberButton(
                                        value: value,
                                        isSelected: selectedReps == value
                                    ) {
                                        selectedReps = value
                                        repsText = "\(value)"
                                        repsFieldFocused = false
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 250)
                }

                // MARK: Weight
                VStack(spacing: 8) {
                    HStack {
                        Text("Weight (lbs)")
                            .font(.title3.bold())

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showPlateCalc.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showPlateCalc ? "xmark" : "plus.forwardslash.minus")
                                    .font(.caption2.bold())
                                if !showPlateCalc {
                                    Text("Plates")
                                        .font(.caption2.weight(.bold))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(showPlateCalc ? Color(.systemGray5) : Theme.primary.opacity(0.12))
                            .foregroundStyle(showPlateCalc ? .secondary : Theme.primary)
                            .clipShape(Capsule())
                        }

                        Spacer()
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .focused($weightFieldFocused)
                            .multilineTextAlignment(.center)
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(Theme.primary)
                            .frame(width: 70)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onChange(of: weightFieldFocused) { _, focused in
                                if focused { weightText = "" }
                            }
                            .onChange(of: weightText) { _, newValue in
                                if let val = Double(newValue) {
                                    selectedWeight = val
                                } else if newValue.isEmpty {
                                    selectedWeight = 0
                                }
                            }
                    }
                    .padding(.horizontal)

                    if showPlateCalc {
                        PlateCalculator(weight: $selectedWeight, weightText: $weightText)
                    }

                    PageIndicator(
                        labels: Self.weightPageLabels,
                        currentPage: weightPage
                    )

                    TabView(selection: $weightPage) {
                        ForEach(Array(weightPages.enumerated()), id: \.offset) { i, values in
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(values, id: \.self) { value in
                                    NumberButton(
                                        value: value,
                                        isSelected: Int(selectedWeight) == value
                                    ) {
                                        selectedWeight = Double(value)
                                        weightText = "\(value)"
                                        weightFieldFocused = false
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 250)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(max(1, selectedReps), max(0, selectedWeight))
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        repsFieldFocused = false
                        weightFieldFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}

// MARK: - Page Indicator

private struct PageIndicator: View {
    let labels: [String]
    let currentPage: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            i == currentPage
                                ? Theme.primary.opacity(0.15)
                                : Color(.systemGray6)
                        )
                        .foregroundStyle(
                            i == currentPage ? Theme.primary : .secondary
                        )
                        .clipShape(Capsule())
                }
                Image(systemName: "hand.draw")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Number Button

private struct NumberButton: View {
    let value: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(isSelected ? Theme.primary : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

// MARK: - Plate Calculator

private struct PlateCalculator: View {
    @Binding var weight: Double
    @Binding var weightText: String
    @State private var customText = ""
    @State private var isSubtracting = false
    @FocusState private var customFocused: Bool

    private let plates = [45, 35, 25, 10, 5]

    var body: some View {
        VStack(spacing: 8) {
            modeToggle
            plateButtons
            customRow
        }
        .padding(.vertical, 6)
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            toggleButton(label: "+ Add", active: !isSubtracting) { isSubtracting = false }
            toggleButton(label: "− Remove", active: isSubtracting) { isSubtracting = true }
        }
        .background(Color(.systemGray5))
        .clipShape(Capsule())
        .padding(.horizontal)
    }

    private func toggleButton(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(active ? (isSubtracting && active ? Color.red.opacity(0.8) : Theme.primary) : Color.clear)
                .foregroundStyle(active ? .white : .secondary)
                .clipShape(Capsule())
        }
    }

    private var plateButtons: some View {
        HStack(spacing: 6) {
            ForEach(plates, id: \.self) { plate in
                Button {
                    applyWeight(Double(plate))
                } label: {
                    Text("\(isSubtracting ? "−" : "+")\(plate)")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSubtracting ? Color.red.opacity(0.1) : Theme.primary.opacity(0.12))
                        .foregroundStyle(isSubtracting ? .red : Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal)
    }

    private var customRow: some View {
        HStack(spacing: 8) {
            TextField("Custom", text: $customText)
                .keyboardType(.decimalPad)
                .focused($customFocused)
                .font(.caption.weight(.semibold).monospacedDigit())
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if customFocused {
                Button {
                    customFocused = false
                } label: {
                    Text("Done")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(Theme.primary)
                }
            }

            Button {
                if let val = Double(customText), val > 0 {
                    applyWeight(val)
                    customText = ""
                    customFocused = false
                }
            } label: {
                Text(isSubtracting ? "Remove" : "Add")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isSubtracting ? Color.red.opacity(0.8) : Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Spacer()

            Button {
                weight = 0
                weightText = ""
            } label: {
                Text("Clear")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
    }

    private func applyWeight(_ value: Double) {
        if isSubtracting {
            weight = max(0, weight - value)
        } else {
            weight += value
        }
        weightText = weight == 0 ? "" : (weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : "\(weight)")
    }
}

// MARK: - Template Picker

struct TemplatePickerSheet: View {
    let date: Date
    let existingLog: DailyLog?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var folders: [TemplateFolder]

    var body: some View {
        NavigationStack {
            Group {
                let nonEmpty = folders.filter { !$0.templates.isEmpty }
                if nonEmpty.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.badge.plus",
                        description: Text("Create a template first.")
                    )
                } else {
                    List {
                        ForEach(nonEmpty) { folder in
                            Section(folder.name) {
                                ForEach(folder.templates) { template in
                                    Button {
                                        applyTemplate(template)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(TemplateColor.color(for: template.colorName))
                                                .frame(width: 12, height: 12)
                                            VStack(alignment: .leading) {
                                                Text(template.name)
                                                    .font(.headline)
                                                Text("\(template.exercises.count) movements")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func applyTemplate(_ template: WorkoutTemplate) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let log = existingLog ?? DailyLog(date: date)
        log.templateColorName = template.colorName
        log.templateName = template.name

        let startOrder = (log.exercises.map(\.order).max() ?? -1) + 1
        for (index, exercise) in template.exercises.sorted(by: { $0.order < $1.order }).enumerated() {
            let copy = LogExercise(name: exercise.name, order: startOrder + index)
            for _ in 0..<exercise.setCount {
                copy.sets.append(LogSet(reps: 0, weight: 0))
            }
            log.exercises.append(copy)
        }

        if existingLog == nil {
            modelContext.insert(log)
        }
    }
}

