# Workout Logger — Spec (v1.1)

Personal iOS workout-logging app replacing the user's old logging app. Single user. App name: TBD (placeholder target name `WorkoutLogger`).
v1.0 is built and in use. **v1.1 changes are listed in order in PLAN-v1.1.md.** This file describes the app as it should be after v1.1.

## 0. Environment
- Built on a Scaleway cloud Mac mini (8 GB+ RAM). Claude Code runs on that Mac and builds with `xcodebuild`. Working rules are in CLAUDE.md.
- Target device: iPhone 16 Pro / Pro Max. Minimum iOS: 18.0.
- GitHub repo. Commit and push at the end of every working session (the cloud Mac gets wiped when deleted).
- Install route: free Apple ID, sign and install via Sideloadly from a Windows PC. The bundle ID is fixed forever (`com.saad.workoutlogger`) so re-signing never wipes data.
- Stack: SwiftUI + SwiftData, MVVM, Swift Charts. No third-party dependencies unless justified.
- Every model has a stable `id: UUID` (needed for import/export de-duplication).
- **The name of the old app ("Shrug") never appears in the app's UI.** Internal type names may keep it.

## 1. Exercise library
- User-defined exercise names. Variants are separate exercises (e.g. "Lat Pulldown – Neutral" and "Lat Pulldown – Wide").
- The only field shown and edited is the **name**. The model still has `equipment` and `weightIncrement`, but they are hidden in the UI and unused (kept to avoid a migration). **No muscle groups.**
- Exercise names are unique (trimmed, case-insensitive, archived exercises included). The form shows an inline error for a duplicate.
- Exercise list: name, with the date it was last used on the right; sorted by last used (most recent first), then by name.
- Deleting:
  - an exercise with **no history** can be deleted;
  - an exercise **with history cannot be deleted**, so offer **Archive** instead.
  - Archived exercises are hidden from pickers and search, their history and graphs are kept, and they can be unarchived from the Exercises tab.
- **Search** (exercise list and exercise picker): split the query into words. A name matches if every word appears in it, in any order, as part of a word, ignoring case and accents. Names starting with the first word rank first. Matched text is highlighted.
- **Create from search** (exercise picker): if no exercise has exactly the typed name, show a row that creates it (each word capitalised), adds it to the workout and opens the set pad.
- Weight conventions:
  - kg only.
  - Smith machine: log plates only (no bar weight).
  - Weighted pull-ups/dips: log added weight only.
  - Unilateral lifts: one entry (no L/R split). The ×2 button (§3) turns a per-side weight into the total.

## 2. Sessions
- Sessions are built live: start an empty session, then add exercises as you go, in the order performed. Adding an exercise opens the set pad for it straight away.
- **Workout name** (e.g. "Anterior", "Posterior"):
  - editable in place on the live workout (no label, placeholder "Workout") and on past workouts;
  - saved 0.5 s after typing stops, not on every keystroke;
  - starting from a template pre-fills it with the template name;
  - if it's empty when tapping Finish, ask for a name (with a Skip option).
- A session holds its exercises, and each exercise holds its sets.
- **Save as template:** from any session, save its exercise list and order as a named template.
- **Start from template:** loads the exercises in order, with no sets.
- **Finish time** = the time of the last logged set (now, if there are no sets). **Duration** = first set → last set.
- **Volume** = Σ weight × reps over Working + Drop sets, shown as e.g. "6,140 kg".
- The active workout is **full screen** with a minimise button. While minimised, a mini-bar above the tab bar shows the name, the elapsed time and the rest time, and tapping it re-opens the workout. The mini-bar also appears after a relaunch if a workout is unfinished (crash safety).
- **History** lives on the Workouts tab (§6):
  - newest first, grouped THIS WEEK / LAST WEEK / Month Year;
  - each row shows the name ("Workout" if unnamed), then `Mon 24/11 · 61 min · 20 sets · 6,140 kg`, plus ` · n PR(s)` in the accent colour if any (the year is added to the date only if it isn't the current year);
  - tap a row to open it;
  - swipe left for an on-row Delete, with **no dialog** and an undo toast instead.
- **Past workout** screen: the name, `Mon 24/11 · 12:02 – 13:03`, a Duration / Sets / Volume card, and each exercise as a compact table with PR marks. Edit can change the date/time and every set.
- Crash safety: persist after every set change.
- Keep the screen awake while a workout is active (`isIdleTimerDisabled`).

## 3. Set logging (core screen, the most important)
- Set fields: weight (kg), reps, and optional RIR (0–5, can be left empty).
- Set types: **Working** (the default; all working sets go to failure) and **Drop set**. No warm-up type.
- **Layout:** each exercise is a section:
  - the name (the current exercise in the accent colour);
  - **+ Set** on the right;
  - a column header SET · KG · REPS · NOTE;
  - one slim row per set, where NOTE holds RIR, Drop and a small PR mark.
  
  There is **no** "Last: 80×8" anywhere.
- **Quick buttons** appear under the current exercise only, after the word "Repeat". The defaults are −1 / −2 / −3, and the values are set in Settings (1–9 each; an empty slot hides that button). Tapping one adds a set with the previous set's weight and reps minus N (minimum 1), with no pop-up.
- **+ Set** opens the **set pad**, a sheet with:
  - the exercise name;
  - Weight / Reps / RIR fields (empty shows "—");
  - a **×2** button and a Working / Drop toggle;
  - a large custom numeric keypad;
  - **Save set**, disabled until weight and reps both have values.
  
  There are **no ± weight buttons**.
- **Prefill:**
  - **First set of an exercise in this workout:** weight = set 1 of that exercise's most recent earlier session. That set's reps are shown only as a grey hint in Reps (not filled in), and the cursor starts in Reps.
  - **Later sets:** weight = the previous set's weight in this workout, and reps are empty.
  - **Exercise never done before:** everything empty.
- **×2:** doubles the weight field, and the doubled total is what gets saved. The hint reads "One side? Tap ×2" and changes to "Doubled. Saved as the total." Typing in Weight clears it. Settings → Show ×2 button can hide it.
- Tap a set to edit it (same set pad). Swipe left to delete a set. Undo the last action with a toast that has an Undo button.
- Haptic feedback when a set is added.
- Key action buttons go in the bottom half of the screen (one-handed reach).
- No progression hints and no "beat last time" colours. PR marks are small and accent-coloured only.

## 4. Rest timer
- A count-up timer that starts automatically when a set is logged and resets to 0:00 when the next set is logged.
- Shown in the **dock** at the bottom of the workout (ring + "REST" + time) and in the mini-bar. The ring fills from 0 to the alert time.
- Tapping the dock opens the **rest sheet**:
  - a big ring;
  - "Alert at 3:00";
  - **−30 s / +30 s**, which move the alert time for this rest period only, staying within 0:30–10:00 and never below the time already elapsed;
  - **Skip rest**, which ends this rest period and cancels its alert.
- When the alert time is reached, a local notification fires (in the background or on the lock screen). One notification per rest period.
- **Lock screen Live Activity** (Settings → Lock screen timer, on by default):
  - the lock screen and Dynamic Island show "Rest", the counting time in the accent colour, and "Alert at 3:00";
  - it starts or updates when a set is logged, and ends on Skip, Finish or discard;
  - it is behind the `LIVEACTIVITY` compile flag in a widget extension (`com.saad.workoutlogger.RestTimer`).
  - **Risk:** with a free Apple ID through Sideloadly this is unverified. There is a build without it, and the notification still works either way.
- **Settings:**
  - Rest alert on/off (the timer still counts when it's off);
  - Alert after: a wheel, 15 s steps, 0:30–10:00, default **3:00**, which applies from the next rest period;
  - Lock screen timer on/off.

## 5. Progress
- Progress tab:
  - an exercise picker;
  - a metric toggle: Estimated 1RM / Top-set weight / Volume (Σ weight × reps for working + drop sets);
  - a chart card showing the current value, the change over the range, the line chart, and the best set with its date;
  - ranges: 1M / 3M / 6M / 1Y / All;
  - **RECENT PRs** list;
  - calendar of training days (tap a day to open that session).
- The per-exercise screen keeps the full history list (every session's sets, newest first).
- e1RM formula: Epley, `w × (1 + reps/30)`, only for sets of ≤12 reps; `reps == 1` → `w`.
- PRs, marked in the session, in history rows (count) and on the past workout screen:
  - Heaviest weight ever for the exercise.
  - Most reps at a given weight (beats every previous set at ≥ that weight).

## 6. Navigation and design
- Tabs: **Workouts** (start + templates + history) / **Exercises** / **Progress** / **Settings** (gear icon).
- **Dark only.** System font, with tabular numbers for all figures.
- Colour tokens:

| Token | Hex | Use |
|---|---|---|
| background | `#0E0F11` | screens |
| surface | `#16181B` | cards, list groups, dock |
| surfaceAlt | `#1A1C20` | search field, inputs |
| raised | `#24272C` | keypad keys, small buttons |
| hairline | `#22252A` | separators |
| border | `#2E3238` | outlined buttons |
| text | `#F2F3F5` | primary text |
| textMuted | `#9BA1A9` | secondary text, section labels |
| textSubtle | `#8A9099` | tertiary text, notes |
| textFaint | `#6B717A` | column headers, set numbers |
| accent | `#C6F432` | "do this now" only: Start, Finish, Save, current exercise, rest time, selected tab, PR |
| onAccent | `#0E0F11` | text on accent |
| destructive | `#E5484D` | Delete |

- Section labels are small caps-style text (13 pt, `textMuted`, e.g. "THIS WEEK"). Grouped cards are 16 pt corner radius. Primary buttons are 48 pt tall; pills and chips are 34 pt. Touch targets are at least 44 pt.
- Supports Dynamic Type.

## 7. Workout CSV import (one-time import from the old app)
- Import a workout CSV via `.fileImporter`: Settings → Import → Workout CSV. The format comes from the real sample `Fixtures/shrug_sample.csv`.
- Mapping screen before committing: every imported exercise name → rename, keep, or merge into another exercise.
- Groups rows into sessions by date/time.
- Idempotent: duplicates are skipped if the import is run again. Records whose ID already exists are **skipped, never overwritten**.
- UI text never names the old app.

## 8. Data and backup
- **Settings → Data**:
  - **Weekly backup to Files**: a switch, on by default, showing "Last: <date>".
  - **Export**, a menu: Backup (JSON) / Spreadsheet (CSV).
  - **Import**, a menu: Backup (JSON) / Workout CSV.
  
  Exports open the iOS Files / share sheet.
- JSON export/import of the full database via `.fileExporter` / `.fileImporter`. Import matches on UUID and skips existing records (**never overwrites** an existing record).
- CSV export (one row per set: date, session, exercise, set #, type, weight, reps, RIR).
- **Weekly automatic backup:**
  - when the app comes to the foreground, if 7+ days have passed since the last one, a JSON backup is written to the app's Documents folder (visible in Files under *On My iPhone › WorkoutLogger*);
  - the newest 8 are kept;
  - this replaces the v1.0 weekly reminder notification.

## 9. Apple Health
- Write each finished session to HealthKit as a strength-training workout (start, end = last set, duration).
- Behind a toggle in Settings.
- **Risk:** HealthKit on a free Apple ID through Sideloadly is unverified. It is isolated behind the `HEALTHKIT` compile flag so the rest of the app ships without it.

## 10. Tests (XCTest)
- **v1.0:** e1RM calculation, both PR rules, session volume, workout CSV parsing (fixture from the real sample), JSON round-trip export → import with no duplicates.
- **v1.1:**
  - finish time;
  - search matching and ranking;
  - create-from-search name;
  - prefill rules;
  - ×2;
  - quick button parsing;
  - rest ring progress and ±30 s limits;
  - backup due date and pruning.

## 11. Build order
v1.0 steps 1–10 are done (see PROGRESS.md). v1.1 follows **PLAN-v1.1.md**: A1–A6, B1–B5, C1–C3.

## Out of scope
Muscle groups (primary/secondary) and weekly sets per muscle, warm-up sets, RPE, alternating/linked sets, progression hints, rotation tracking, session notes, Whoop field, bodyweight log, Apple Watch, home-screen widgets (the rest-timer Live Activity is the only widget-extension feature), iCloud sync, Arabic, Face ID, light mode, per-exercise equipment and weight increments in the UI. Voice logging and AI features are planned for v1.2.
