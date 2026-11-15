# Workout Logger — v1 Spec

Personal iOS workout-logging app replacing Shrug. Single user. App name: TBD (placeholder target name `WorkoutLogger`).

## 0. Environment
- Built on a Scaleway cloud Mac mini M1 (8 GB RAM). Claude Code runs on that Mac and builds with `xcodebuild`. Working rules are in CLAUDE.md.
- Target device: iPhone 16 Pro / Pro Max. Minimum iOS: 18.0.
- Private GitHub repo. Commit and push at the end of every working session (the cloud Mac gets wiped when deleted).
- Install route: free Apple ID, sign and install via Sideloadly from a Windows PC. Keep the bundle ID fixed forever (e.g. `com.saad.workoutlogger`) so re-signing never wipes data.
- Stack: SwiftUI + SwiftData, MVVM, Swift Charts. No third-party dependencies unless justified.
- Every model has a stable `id: UUID` (needed for import/export de-duplication).

## 1. Exercise library
- User-defined exercise names. Variants are separate exercises (e.g. "Lat Pulldown – Neutral" and "Lat Pulldown – Wide").
- Fields: name, primary muscle, secondary muscles (multi), equipment tag (Smith / Machine / Cable / Dumbbell / Barbell / Bodyweight), weight increment (per exercise, e.g. cable 5 kg, DB 2 kg).
- Muscle groups are a fixed list (enum stored as String raw values, not free text): Chest, Lats, Upper Back, Lower Back, Traps, Front Delts, Side Delts, Rear Delts, Biceps, Triceps, Forearms, Abs, Quads, Hamstrings, Glutes, Adductors, Calves. Equipment is also a fixed enum (the six tags above).
- Deleting: an exercise with **no history** can be deleted. An exercise **with history cannot be deleted**; offer **Archive** instead. Archived exercises are hidden from pickers and search, their history and graphs are kept, and they can be unarchived from the Exercises tab.
- Settings toggle: **"Secondary muscles" ON by default**. When OFF, hide the secondary-muscle UI and count only primary muscles in volume.
- Search the exercise list by name.
- Weight conventions:
  - kg only.
  - Smith machine: log plates only (no bar weight).
  - Weighted pull-ups/dips: log added weight only.
  - Unilateral lifts: one entry (no L/R split).
- Initial library comes from the Shrug CSV import (section 7).

## 2. Sessions
- Sessions are built live: start an empty session, add exercises as you go, in the order performed.
- A session holds its exercises, and each exercise holds its sets.
- **Save as template:** from any session, save its exercise list and order as a named template.
- **Start from template:** loads the exercises in order with **no sets and no weights/reps pre-filled**.
- Duration: automatic, from the first set logged to the last.
- Edit past sessions, including the date/time and every set.
- Crash safety: persist after every set change. If the app is killed mid-workout, show a "Resume workout" banner on relaunch.
- Keep the screen awake while a workout is active (`isIdleTimerDisabled`).

## 3. Set logging (core screen — most important)
- Set fields: weight (kg), reps, optional RIR (0–5, can be left empty).
- Set types: **Working** (default; all working sets are to failure) and **Drop set**. No warm-up type.
- Beside each set, show last session's matching set for that exercise, e.g. `Last: 80×8`.
- Add-set controls on each exercise card:
  1. **−1 / −2 / −3 buttons:** instantly add a new set with the same weight as the previous set and reps = previous set's reps minus 1/2/3 (minimum 1). No pop-up.
  2. **"+ Set" button:** opens a small pop-up pre-filled with the previous set's weight and reps (from this session, or from the last logged set of this exercise in history if none yet today). The user can edit the values or just tap Save.
- The pop-up uses a **custom large numeric keypad** (big keys, one-handed, bottom of screen) with fields for weight, reps and RIR. Weight also gets ± buttons that step by the exercise's increment.
- Tap a set to edit it (same pop-up). Swipe to delete a set. Undo the last action (toast with an Undo button).
- Haptic feedback when a set is added.
- Key action buttons go in the bottom half of the screen (one-handed reach).
- No progression hints and no "beat last time" colours.

## 4. Rest timer
- A count-up stopwatch that starts automatically when a set is logged and resets to 0:00 when the next set is logged.
- When the rest alert time is reached it fires a local notification (works with the app in the background or on the lock screen). One notification per rest period.
- **Settings → Rest alert time:** a scroll wheel picker (minutes + seconds, 15 s steps, range 0:30–10:00), default **3:00**. Changes apply from the next rest period. A toggle turns the alert off entirely (the timer still counts).
- Visible on the active workout screen.

## 5. Progress
- Per-exercise screen: a graph plus the full history list (every session's sets, newest first).
- Graph metric toggle: Estimated 1RM / Top-set weight / Volume (sum of weight × reps for working + drop sets).
- e1RM formula: Epley, `w × (1 + reps/30)`, only for sets of ≤12 reps; `reps == 1` → `w`.
- Ranges: 1M / 3M / 6M / 1Y / All.
- PR badges (shown in the session and in history):
  - Heaviest weight ever for the exercise.
  - Most reps at a given weight (beats every previous set at ≥ that weight).
- Progress tab:
  - Weekly sets per muscle group (Mon–Sun). Primary muscle = 1 set, secondary = 0.5 (secondary ignored when the setting is OFF). Counts working + drop sets.
  - Calendar of training days (tap a day to open that session).

## 6. Navigation and design
- Tabs: Workout / History / Exercises / Progress / Settings.
- Clean native iOS style, follows the system light/dark theme, blue accent (system default).
- Supports Dynamic Type.

## 7. Shrug import (one-time)
- Import a Shrug CSV via `.fileImporter`.
- **Column mapping must be built from a real sample Shrug CSV. Do not guess the format.** Stop and ask for the sample file before implementing the parser.
- Mapping screen before committing: every Shrug exercise name → rename, keep, or merge into another exercise.
- Groups rows into sessions by date/time.
- Idempotent: duplicates are skipped if the import is run again. Records whose ID already exists are **skipped, never overwritten**.

## 8. Data and backup
- **Settings → Data section** with clearly labelled buttons: "Export backup (JSON)", "Export to CSV", "Import backup (JSON)", "Import from Shrug (CSV)". Exports open the iOS share sheet / Files picker so the file can be saved to Files, AirDropped or sent.
- JSON export/import of the full database via `.fileExporter` / `.fileImporter`. Import matches on UUID and skips existing records (**never overwrites** an existing record).
- CSV export (one row per set: date, session, exercise, set #, type, weight, reps, RIR).
- Weekly local-notification reminder to back up, with a toggle in Settings.

## 9. Apple Health
- Write each finished session to HealthKit as a strength-training workout (start, end, duration).
- Behind a toggle in Settings.
- **Risk:** HealthKit capability support on a free (personal team) Apple ID, and through Sideloadly re-signing, is unverified. If the build fails to sign or the entitlement is stripped, isolate HealthKit behind a compile flag so the rest of the app ships without it.

## 10. Tests (XCTest)
- e1RM calculation, both PR rules, weekly muscle-volume counting (with the secondary toggle on and off), Shrug CSV parsing (fixture from the real sample), JSON round-trip export → import with no duplicates.

## 11. Build order
1. Project setup, SwiftData models, tabs, git repo.
2. Exercise library CRUD.
3. Active workout screen: sessions, set logging, quick buttons, keypad pop-up, undo, crash-safe persistence, keep-awake.
4. Rest timer + notification.
5. History and editing past sessions; templates.
6. Progress: graphs, PRs, weekly volume, calendar.
7. Shrug import (after the sample CSV is provided).
8. JSON/CSV export, backup reminder.
9. HealthKit.
10. Tests passing → archive → export the IPA for Sideloadly.

## Out of scope (v1)
Warm-up sets, RPE, alternating/linked sets, progression hints, rotation tracking, session notes, Whoop field, bodyweight log, Apple Watch, widgets, iCloud sync, Arabic, Face ID.
