# Architecture — RepVault

## Overview
A native iOS lift-tracking app built with **SwiftUI** and **SwiftData**. Users view a calendar, tap a date, and log workouts by applying reusable templates or adding individual movements. The interface is optimized for one-handed, thumb-zone usage.

## Tech Stack
- **UI**: SwiftUI (iOS 17+)
- **Persistence**: SwiftData (on-device, no server)
- **Navigation**: `NavigationStack` with value-based `navigationDestination`
- **Charts**: Swift Charts (MovementDetailView reps-over-time)
- **Live Activities**: ActivityKit (rest timer on Lock Screen + Dynamic Island)
- **Icons**: Custom-generated via nano-banana MCP (Google Gemini)

## Data Models

All models are SwiftData `@Model` classes stored in a single `ModelContainer`.

```
TemplateFolder
├── name: String
└── templates: [WorkoutTemplate]   (cascade)

WorkoutTemplate
├── name: String
├── colorName: String              (hex string or named preset, default "blue")
├── folder: TemplateFolder?
└── exercises: [Exercise]          (cascade)

Exercise
├── name: String
├── setCount: Int              (default 3, used when applying template)
├── order: Int                 (default 0, for drag-to-reorder in editor)
└── template: WorkoutTemplate?

Movement
├── name: String
└── category: String               (comma-separated: Chest, Back, Shoulders, Quads, Hamstrings, Glutes, Calves, Biceps, Triceps, Forearms, Core)

DailyLog
├── date: Date
├── templateColorName: String?
├── templateName: String?
├── notes: String              (default "")
├── startTime: Date?           (set when first set is logged)
├── endTime: Date?             (set on each set logged, or when workout is finished)
├── isFinished: Bool           (default false — explicit finish or auto-timeout)
├── wasTimedOut: Bool          (default false — true when auto-timeout at 4h)
└── exercises: [LogExercise]       (cascade)

LogExercise
├── name: String
├── order: Int                     (for drag-to-reorder persistence)
├── sets: [LogSet]                 (cascade)
└── dailyLog: DailyLog?

LogSet
├── reps: Int
├── weight: Double
└── logExercise: LogExercise?
```

### Relationships
| Parent | Child | Delete Rule |
|--------|-------|-------------|
| `TemplateFolder` | `WorkoutTemplate` | cascade |
| `WorkoutTemplate` | `Exercise` | cascade |
| `DailyLog` | `LogExercise` | cascade |
| `LogExercise` | `LogSet` | cascade |

### Why two exercise types?
`Exercise` lives inside a template (the blueprint). `LogExercise` is a copy that lives inside a `DailyLog` (the actual workout record). Editing a template won't retroactively change past logs.

### Seeded Data
On first launch (`RepVaultApp.init`):
- 154 default `Movement` records across 11 categories (Chest, Back, Shoulders, Quads, Hamstrings, Glutes, Calves, Biceps, Triceps, Forearms, Core) — multi-target exercises use comma-separated categories
- Two default `TemplateFolder`s: "My Templates" + "Starter Templates"
- 6 starter templates: Push Day, Pull Day, Leg Day, Upper Body, Lower Body, Full Body
- If the SwiftData schema changes, the old store is wiped and re-created

### Date Restrictions
- Future dates are dimmed and non-tappable in the calendar
- DayDetailView hides action buttons (Add Movement, Apply Template) for future dates
- Users can only log workouts for today or past dates

### Empty Set Filtering
Template application creates placeholder sets (0 reps / 0 weight). These are excluded from:
- Stats (total sets, total reps, body part counts including volume)
- CSV export
- MovementDetailView charts
- PR calculations

## View Hierarchy

```
RepVaultApp
└── ContentView (TabView)
    ├── Tab 1: Calendar
    │   └── NavigationStack
    │       └── CalendarView (LazyVGrid month calendar + recent workouts)
    │           └── DayDetailView (via navigationDestination for Date)
    │               ├── TemplatePickerSheet (modal)
    │               ├── MovementPickerSheet (modal)
    │               ├── AddSetSheet (modal, includes PlateCalculator)
    │               ├── EditSetSheet (modal, includes PlateCalculator)
    │               └── WorkoutInputSheet (modal, iOS 26+)
    ├── Tab 2: Templates
    │   └── NavigationStack
    │       └── TemplateListView (folders + templates)
    │           └── TemplateEditorView (edit name, ColorPicker, exercises)
    │               └── MovementPickerSheet (modal)
    ├── Tab 3: Movements
    │   └── NavigationStack
    │       └── MovementLibraryView (search, category filter, movement list)
    │           ├── MovementDetailView (chart with time range filter)
    │           └── AddMovementSheet (modal — create new movement)
    └── Tab 4: Stats
        └── NavigationStack
            └── StatsView (summary cards, bar charts, template usage)
```

## Key Flows

### Viewing the Calendar
1. `CalendarView` computes day cells for the displayed month.
2. `@Query` fetches all `DailyLog` records; a colored dot (matching template color) marks days with logs.
3. Today's date gets a Theme.primary highlight (rounded rectangle).
4. Day cells are 44pt minimum for thumb-friendly tapping. Future dates are dimmed and non-tappable.
5. Month transitions use spring animations; month title crossfades with `.contentTransition(.numericText())`.
6. "Open Today" button with "TODAY" label and "Start Workout" text.
7. **Recent workouts** section shows last 3 past-day workouts with template color accent bars and duration.

### Navigating to a Day
1. Tapping a `DayCell` pushes a `Date` value onto `NavigationStack`.
2. `.navigationDestination(for: Date.self)` resolves to `DayDetailView`.
### Logging a Workout
1. `DayDetailView` shows exercises for the selected date's `DailyLog`, sorted by `order`.
2. A **bottom floating action bar** provides thumb-zone access to "Add Movement" and "Template".
3. Each exercise section shows its sets (reps x weight) with "Add Set" buttons.
4. Sets are logged via paginated grid pickers (reps 1-30, weight 5-500 lbs in 5lb increments) or typed inline.
5. **Plate calculator** toggles open via "Plates" button next to weight field — quick-add/subtract standard plates (45, 35, 25, 10, 5) or custom amounts, with +/- mode toggle and clear.
6. Swipe-to-duplicate sets (fills empty template placeholder sets first, then appends new). Swipe-to-delete sets.
7. **Reorder exercises** via up/down chevron buttons in edit mode (EditButton in toolbar).
8. **Rest timer** auto-starts after adding/duplicating a set (default 90s, configurable 15s–5min via wheel picker).
   - Settings live in a section at the top of the day detail screen (toggle + duration picker).
   - Timer preferences persist across days via `@AppStorage` (`restDuration`, `timerEnabled`).
   - Countdown with circular progress ring, skip button. Haptic buzz on finish.
   - **Live Activity** (Lock Screen + Dynamic Island) shows countdown when phone is locked.
   - Uses ActivityKit with `RestTimerAttributes` (shared between main app and widget extension).
9. **Workout duration timer**: Live counting-up timer starts when first set is logged (`startTime`). Shows elapsed time in `M:SS` or `H:MM:SS` format. "Finish Workout" button stops the timer. Auto-timeout at 4 hours with warning haptic.
10. **Haptic feedback** fires on key actions (add set, duplicate, apply template, reorder, timer done, finish workout).
11. **PR badges**: Crown icon for weight PRs, flame icon for rep PRs at a given weight.
12. **AI-powered input** (iOS 26+): Tap the sparkle icon to describe a workout in natural language.
13. **Previous workout link**: Shows "Last [Template Name]" with date, linking to that day's log.
14. **Notes**: Free-text workout notes field with keyboard Done button.
15. **Share**: Share button exports a text summary of the workout.
16. **Clear Workout**: Trash button with confirmation alert resets all exercises, template info, and timer state.

### Applying a Template
1. User taps **Template** in the floating bar.
2. A half-sheet (`TemplatePickerSheet`) lists all `WorkoutTemplate` records with color dots.
3. Selecting a template copies exercises (sorted by `order`) into a new/existing `DailyLog` with placeholder sets (0 reps / 0 weight) based on each exercise's `setCount`.
4. Stamps `templateColorName` + `templateName` on the log.

### Managing Templates
1. `TemplateListView` shows folders with disclosure groups.
2. Each folder expands to show templates with left accent bars in template color.
3. Tapping a template navigates to `TemplateEditorView`.
4. Editor allows renaming, choosing a color via SwiftUI **ColorPicker** (stored as hex string), and adding/removing/reordering exercises via `MovementPickerSheet`.
5. Templates can be moved between folders via context menu.

### Movement Picker
1. Horizontal scrolling capsule pills filter by body part category.
2. Search bar allows finding or creating new custom movements.
3. Multi-select with checkmark toggles; "Add (N)" confirms selection.

### Movement Library
1. `MovementLibraryView` shows all movements sorted alphabetically, grouped by first letter.
2. Dropdown menu filters by category (All, Chest, Back, Shoulders, etc.).
3. `.searchable` bar filters movements by name (case-insensitive).
4. Each row is a `NavigationLink` that pushes to `MovementDetailView`.
5. Toolbar "+" button presents `AddMovementSheet` — a form with name TextField and FlowLayout category capsule selector.
6. Swipe-to-delete with **two-step confirmation** (warns about data loss, then "are you sure?").

### Movement Detail (Reps Over Time Chart)
1. `MovementDetailView` shows category badges and a **reps-over-time chart**.
2. Queries all `DailyLog` records to find every set logged for this movement (filters out 0/0 placeholder sets).
3. Horizontal scrolling capsule pills show only weights the user has actually logged.
4. Selecting a weight displays a line chart (Swift Charts) with categorical string X-axis labels.
5. **Time range filter**: Segmented picker (1M, 3M, 6M, 1Y, All) filters chart data.
6. Summary bubbles below the chart show Best reps, Session count, and Trend.
7. **Weight PR** and **Rep PR** badges displayed at the top.
8. On appear, auto-selects the most recently used weight.

### Stats
1. Segmented picker filters by Week / Month / Year.
2. Summary cards show workout days, total sets, total reps (excluding empty placeholder sets).
3. Animated bar chart shows body part breakdown with 3-way segmented picker (Sets / Reps / Volume). Volume values use compact K/M formatting.
4. Template usage section shows which templates were used and how often.

### Settings
1. Gear icon in Calendar tab toolbar opens a settings sheet.
2. **Dark mode toggle** (persisted via `@AppStorage`).
3. **Color theme picker** with multiple palettes (Burgundy, Ocean, Forest, etc.) — each showing 3 preview circles.
4. **CSV export**: Generates a CSV file with columns (Date, Template, Exercise, Set, Reps, Weight, Duration). Empty placeholder sets are excluded. Shared via `ShareLink`.

## UX Design Principles
- **Motion-first**: Optimized for one-handed, thumb-zone usage
- **44pt minimum tap targets**: All interactive elements meet Apple HIG
- **Bottom-aligned actions**: Primary actions in floating bar at bottom of screen
- **Haptic feedback**: Confirms key interactions (add, duplicate, apply, reorder, timer, finish)
- **Large grid pickers**: Reps and weight selected via big, tappable number buttons
- **Portrait-only**: Orientation locked to portrait

## Visual Language
- **Dark/Light mode** toggled via Settings (default dark), persisted via `@AppStorage("isDarkMode")`
- **Theme.swift** provides centralized colors via `ColorPalette` enum:
  - Multiple palettes: Burgundy (default), Ocean, Forest, Sunset, Lavender, Slate, etc.
  - Each palette defines `primary`, `secondary`, `accent` colors
  - `Theme.primary`, `Theme.accent`, `Theme.secondary` resolve based on `@AppStorage("colorPalette")`
- **Tracked uppercase headers**: Section labels use `.font(.caption.weight(.heavy)).tracking(1-2)`
- **Left accent bars**: 4pt colored vertical strips on cards (template color, PR type, etc.)
- **Custom empty states**: Serif em-dash character + headline + subheadline
- **No gradients**: All fills are flat solid colors

## Color System
`TemplateColor` supports both named presets (red, orange, yellow, green, blue, purple, pink, teal, indigo) and **arbitrary hex strings** via `Color(hex:)` extension and `hexString(from:)` converter. Templates use SwiftUI `ColorPicker` for full color wheel selection.

## Assets
- `Assets/AppIcon.png` — App icon (dumbbell on dark navy)
- `Assets/CategoryIcons/` — 7 body part category icons

## File Map

```
RepVault/
├── RepVaultApp.swift              App entry, ModelContainer, seed data
├── Models/
│   ├── TemplateFolder.swift           Folder grouping templates
│   ├── WorkoutTemplate.swift          Template with name, color, exercises
│   ├── Exercise.swift                 Template exercise (name, setCount, order)
│   ├── DailyLog.swift                 Daily log with date, template info, duration tracking
│   ├── LogExercise.swift              Logged exercise with sets and order
│   ├── LogSet.swift                   Individual set (reps + weight)
│   ├── Movement.swift                 Global movement library entry
│   └── RestTimerAttributes.swift      ActivityKit attributes (shared with widget ext)
├── Views/
│   ├── ContentView.swift              Root TabView + Settings sheet (theme, CSV export)
│   ├── CalendarView.swift             Month grid calendar + DayCell + recent workouts
│   ├── DayDetailView.swift            Day detail + floating bar + set sheets + PlateCalculator
│   ├── TemplateListView.swift         Folder/template list + TemplateRow
│   ├── TemplateEditorView.swift       Template editor (name, ColorPicker, exercises)
│   ├── MovementLibraryView.swift      Movement library tab (browse, search, add, 2-step delete)
│   ├── MovementPickerSheet.swift      Movement search/select with categories
│   ├── MovementDetailView.swift       Movement chart (time range filter, weight/rep PRs)
│   ├── StatsView.swift                Stats dashboard + StatCard
│   ├── WorkoutInputSheet.swift        AI natural language workout input (iOS 26+)
│   └── TemplateColor.swift            Color palette helper (named + hex colors)
├── Theme.swift                        Centralized theme colors (multi-palette system)
├── Assets/
│   ├── AppIcon.png                    Generated app icon
│   └── CategoryIcons/                 7 body part category icons
├── CLAUDE.md                          AI assistant instructions
└── ARCHITECTURE.md                    This file
```
