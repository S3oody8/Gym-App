# PLAN v1.1.1: fixes from the first week on the phone

This is the user's feedback after using v1.1 on the iPhone. It overrides SPEC.md where they conflict. Update SPEC.md to match as you go.

Same ground rules as v1.1:
- Edit the existing app; don't rebuild it.
- Don't change the bundle ID.
- Don't delete or rename any model property.
- No "Shrug" in the UI.
- Do one step at a time. After each step: build clean, run the tests, commit, push, then stop and summarise.

The release is MARKETING_VERSION 1.1.1, build 3. Produce the same three IPAs as v1.1.

---

## F0. Reorganise the folders by feature (no code changes)

The user asked for the project to be laid out the way well-run public apps are. Most SwiftUI apps of this size group code **by feature**, not by layer:

```
WorkoutLogger/
  App/                  WorkoutLoggerApp, RootTabView, mini-bar
  Core/
    Models/             SwiftData models (unchanged)
    Persistence/        WorkoutStore, migrations, ModelContainer setup
    Services/           Health, notifications, Live Activity, backup
    Logic/              pure Swift: e1RM, PRs, metrics, formats (unit tested)
  Features/
    Workouts/           history tab, past workout, session editor
    ActiveWorkout/      live workout, set pad, rest dock/sheet, exercise picker
    Exercises/
    Progress/
    Settings/
    Import/             CSV import + mapping
  Shared/
    UI/                 Theme, SectionLabel, UndoToast, reusable components
    Utilities/
RestTimerWidget/        (unchanged)
WorkoutLoggerTests/     mirror the same feature folders
```

The rules:
- Only move files. Don't change type names or logic. Features must not import each other's views, only Core and Shared.
- Run `xcodegen generate` afterwards. All 98+ tests must still pass.
- Update the folder-layout line in CLAUDE.md §5 to match.
- Do this as its own commit.

This makes the code easier to work in. It doesn't affect speed; F1 handles the lag.

## F1. Lag (do this FIRST, before F0)

The user's top complaint is that the app is "really laggy". The phone has about 300 imported workouts, so any work that grows with history is felt everywhere. Below are the causes found in the code, ranked by impact. Fix them in this order, measuring as you go.

### 1. The PR detector is quadratic: `Utilities/PRDetector.swift`

`badges(for:)` loops over every set, and for each one it rebuilds `earlier.map(\.weight).max()` and `earlier.filter { $0.weight >= w }` over **all earlier sets**. That is O(n²) per exercise. An exercise with 800 sets costs about 640,000 steps, times three passes.

Rewrite it as one pass with running state, keeping exactly the same results:
- `maxWeight: Double` so far.
- `maxRepsByWeight: [Double: Int]`, the best reps at each distinct weight. For the reps check, look only at the weights ≥ w. An exercise has few distinct weights, so this is close to O(n).
- Update the state *after* each set, as the `defer` does now.
- The existing PR tests must pass unchanged. Add a test that compares the old and new algorithms on about 2,000 random sets, plus a timing test.

### 2. PRs are recalculated during drawing

PRs are recalculated over the whole history inside SwiftUI `body`:
- `WorkoutsTabView` line ~45 calls `viewModel.prCounts(...)`. That redoes every exercise's PRs on every redraw of the history tab: scrolling, the undo toast, the tab switch.
- `ExerciseCardSection` line ~13 calls `viewModel.prBadges(for: entry)` for every card on every redraw of the live workout.
- `PastWorkoutView` line ~69 does the same for each entry.

The fix is to add a `PRCache`. It is a plain `@MainActor @Observable` class, held once by the app and passed through the environment.
- `badges(for exerciseID) -> [UUID: PRBadges]` is computed lazily and stored.
- `countsBySession -> [UUID: Int]` is built from the cached per-exercise results and stored.
- `invalidate(exerciseID:)` runs after add, edit or delete set, undo, remove entry, or delete/restore session (in `WorkoutStore`, or the view models that call it). `invalidateAll()` runs after import, JSON restore and the debug seed.
- Views only read the cache and never compute PRs in `body`.

### 3. Relationship walking faults objects one at a time

`ProgressQueries.prInputs`, `WorkoutStore.lastSessionSets`, `session.allSets`, `session.load` and `Exercise.lastUsed` walk SwiftData relationships. Each access can fault a single object.
- When building the cache, fetch the sets in one `FetchDescriptor<WorkoutSet>` with `relationshipKeyPathsForPrefetching` (the entry, the session, the exercise) instead of walking relationships.
- History rows call `session.allSets.count` and `session.load` on every row draw. Cache a small row summary per session id (sets, volume, duration) in `HistoryViewModel`, and invalidate it with the same events as the PR cache.
- The Exercises and Progress tabs sort by `lastUsed`. Compute that once in a dictionary, not per comparison.

### 4. Timer redraws

`RestDock`, `RestSheet` and `WorkoutMiniBar` tick every second. Each `TimelineView` must wrap **only** the timer `Text`/ring, and must not read the view model or the session inside the closure. Otherwise the whole workout screen re-renders every second, which is what makes the live workout feel sticky. Use `Self._printChanges()` in a Debug build to confirm the card sections don't re-evaluate on every tick, then remove it.

### 5. Only if still slow after 1 to 4

Build the PR cache on a background `@ModelActor` at launch, and publish the results to the main actor. Do this only if the timings below still miss the targets.

### How to measure (report the numbers)
- Add a `DebugSeeder` scenario with **300 workouts, about 15 exercises and about 6,000 sets**, spread over 2 years.
- Add `XCTest` `measure {}` tests on that seed for three things: building the PR cache, building the history PR counts, and computing one exercise's badges.
- Report the before and after timings in the step summary.
- **Targets:** a full PR cache build under 150 ms on the simulator. After the cache is warm, nothing PR-related runs during scrolling or timer ticks. Logging a set recomputes only that exercise, in under 10 ms.
- No model changes are needed. This is all caching and algorithm work.
- After this step, build the Release IPAs so the user can try the fix on the phone before the other steps.

## F2. Rest timer: separate it from the sets

**The problem:** the timer is derived from the latest set's `loggedAt` (`RestTimerStore.sync`). So deleting the second set jumps the timer back to the first set's time, and editing or undoing moves it too. To the user it feels random. They also can't restart it manually.

**The new rules:**
- The timer has its own start time. Nothing changes it except the events below.
- **Saving a new set** (including ×2 and the quick buttons) restarts it at 0:00 and uses the alert time from Settings.
- **Deleting, editing or undoing a set never touches the timer.**
- A **Restart** button in the rest dock and the rest sheet restarts it at 0:00, next to ±30 s and Skip. Restart also brings back a skipped timer.
- Finish or discard ends it. Keep the notification and the Live Activity in step with every change.
- Replace `sync(lastSetAt:)` with `restart(sessionID:)`. Call it from "set added" and from the Restart button only.
- Update RestTimerStoreTests and RestTimerTests. Add these tests:
  - Deleting the latest set leaves the start time unchanged.
  - Restart resets the start time and re-schedules the alert.
  - Restart after Skip shows the timer again.
- No model change is needed. The period is already stored in UserDefaults.

## F3. Don't highlight the last-used exercise

- Remove the accent colour on the current exercise's name (`ExerciseCardSection` line ~50) and any other "current" styling.
- The timer is shown only in the bottom dock. Nothing on an exercise row shows timer state.
- Assumption to confirm with the user: keep the quick-repeat buttons under the exercise that has the most recent set, just without the highlight.

## F4. Dynamic Island cut off ("0:..." when music is playing)

The user's screenshot shows the timer squeezed to "0:..." while music shares the island.

The fix, in `RestTimerWidget/RestTimerLiveActivity.swift`:
- **minimal:** show a small circular `ProgressView(timerInterval:countsDown:)` ring in the accent colour (or the dumbbell icon) instead of text. Text never fits there.
- **compactTrailing:** `Text(timerInterval:)` with `.monospacedDigit()`, a fixed frame wide enough for "10:00" (about 44 pt), and `.minimumScaleFactor(0.8)`. It must never show an ellipsis.
- If possible, check it in the simulator with a second Live Activity running.

## F5. Add exercise: keyboard opens straight away

When "Add exercise" opens the picker, the search field is focused and the keyboard is up, ready to type. Use `.searchable(text:isPresented:)` set to true on appear, or a focused `TextField`.

## F6. Tap an exercise in the live workout to see its history

- Tapping the exercise name in the live workout opens that exercise's history as a sheet over the workout: past sessions, newest first, each with date and sets. Reuse the existing exercise history/progress screen.
- Closing the sheet returns to the workout, with nothing lost.
- Keep long-press for the existing menu (remove exercise, etc.).

## F7. Interactive Progress charts

- Touch and drag on the chart to scrub (`chartXSelection`). A vertical rule and a callout show the date and value of the nearest point.
- Tapping a point opens that past workout.
- Keep it subtle and in the dark theme.

## F8. Imported workouts show "Workout" instead of their names

The CSV import never read a workout name. The parser only reads Workout Start, Exercise, Weight, Unit, Reps and Reps/Secs, and `Fixtures/shrug_sample.csv` has no name column.

- **Before coding, ask the user** for a few lines from the top of the real export file, header included, to see which column holds the name. Do not guess.
- If there is a name column: read it into `ShrugRow`, set `WorkoutSession.name` when creating a session, and on re-import fill the name of existing imported sessions only when it is empty. Re-import is already de-duplicated by id, so the user can re-run the import to backfill names without duplicating sets.
- If the export really has no names, stop and tell the user. Don't invent names.

---

## Order
**F1 first** (then give the user the IPAs to test the lag), then F0, F2 + F3 (one step), F4, F5, F6, F7, F8, then release 1.1.1.
