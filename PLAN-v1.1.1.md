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

Tell the user honestly that this makes the code easier to work in but **does not by itself fix the lag**. F1 fixes the lag.

## F1. Lag

The user says the app is "really laggy." These are the likely causes found in the code:
1. **History tab:** `WorkoutsTabView.body` calls `viewModel.prCounts(exercises:sessions:)`, which recomputes PRs for every exercise across all history on every redraw.
2. **Live workout:** `ExerciseCardSection` calls `viewModel.prBadges(for:)`, which runs `PRDetector` over the exercise's whole history for every card on every redraw. The 1-second rest timer redraws mean this runs constantly.
3. **Past workout:** `PastWorkoutView` does the same per entry.
4. `session.allSets` and `isCurrent` scan every set on each redraw.

What to do:
- Compute PR data once and cache it in the view model. Recompute only when sets change: add, edit, delete, undo, import or restore.
- Move the history PR counts off the main thread or into a cached result. Never compute them in `body`.
- Make sure each `TimelineView` wraps only the timer `Text`, so the timer ticking doesn't re-render the rest of the screen.

How to check it:
- Add a debug seed with about 300 workouts, which is the size of the user's imported history. Add a unit/performance test that times the PR and history computations on that data.
- Report the timings before and after the fix.
- Then build Release (the IPA is Release) and check that scrolling the history, opening a past workout and logging a set all feel instant in the simulator.

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
F0, F1, F2 + F3 (one step), F4, F5, F6, F7, F8, then release 1.1.1.
