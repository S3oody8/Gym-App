# PLAN v1.1

v1.0 has been used at the gym for about a week. This plan turns that feedback into v1.1.
SPEC.md has been updated to match and is still the source of truth. This file is the **order of work**.
Section numbers like "SPEC §3" point to SPEC.md.

The screens were agreed as mockups. Claude on the Mac can't open them, so everything they show is written out below and in SPEC §6.

## Ground rules for v1.1
- **Edit the existing app.** Don't start over. Keep the 95 tests passing.
- **No SwiftData model changes.** `Exercise.equipment` and `Exercise.weightIncrement` stay in the model and are hidden in the UI. New settings go in `UserDefaults` / `@AppStorage` (keys in `SettingsKeys`). If a step seems to need a model change, stop and ask.
- **Bundle ID stays `com.saad.workoutlogger`.** The Live Activity extension gets `com.saad.workoutlogger.RestTimer`.
- **The word "Shrug" must never appear in the app's UI.** That includes button labels, titles, messages, errors and search prompts. Internal type and file names (`ShrugCSVParser` and so on) may stay.
- Work one step at a time. After each step: build clean → tests → commit → push → stop, then summarise what's done, the assumptions you made and what's next, and wait for "continue".
- Add unit tests for every piece of pure logic listed under a step.

---

## Group A — Quick fixes

### A1. Finish time = time of the last set
- `WorkoutStore.finish` sets `finishedAt` to the **time of the last logged set**. Use now only if the session has no sets.
- Duration (first set → last set), the history row and the Health workout end all use it.
- Tests: finish with sets, then without sets.

### A2. Flexible exercise search
- Split the query on spaces. A name matches when **every word appears somewhere in it**, in any order and as part of a word. Ignore case and accents. Example: "neutral lat" finds "Lat Pulldown – Neutral".
- Ranking: names that start with the first word come first, then alphabetical order.
- Highlight the matched parts of each result in the accent colour, semibold.
- Don't show any hint text under the search field.
- Use it in the exercise picker and on the Exercises tab.
- Tests: word order, partial words, case and accents, no match.

### A3. Create from search, and open the set pad after adding
- In the exercise picker, when the query isn't empty and **no exercise has exactly that name** (trimmed, ignoring case), show a dashed row at the end of the results:
  - **Create "<Name>"**, where the name is the query trimmed with each word's first letter capitalised;
  - with "Adds it to this workout and opens the set pad" underneath.
- Tapping it creates the exercise (the uniqueness rules still apply), adds it to the workout and **opens the set pad straight away**.
- Picking an existing exercise also opens the set pad straight away.
- Tests: name normalisation; the row is hidden when there's an exact match.

### A4. Typing lag in the workout name
- `WorkoutNameField` keeps the text locally and saves it **0.5 s after the last keystroke**, and also when you press Return or leave the screen. Don't save on every keystroke.

### A5. Delete in History
- Swiping a history row left shows a red **Delete** on that row. A full swipe deletes too.
- **No confirmation dialog.** The workout is removed and the existing **undo toast** appears for 5 s.
- Rename stays available, either as a second swipe action or on the workout detail screen through Edit.

### A6. Remove "Shrug" from the UI, and two data buttons
- Settings → Data now has only two rows. Each opens a menu:
  - **Export** → "Backup (JSON)", described as "Everything, to restore later", and "Spreadsheet (CSV)", described as "All sets, opens in Excel".
  - **Import** → "Backup (JSON)" and "Workout CSV". Workout CSV is the existing CSV import flow.
- Footnote under the section: "Import takes a backup (JSON) or a workout CSV."
- Rewrite every visible string that mentions Shrug, for example:
  - "Import from Shrug" → "Import workout CSV";
  - "This doesn't look like a Shrug export…" → "This doesn't look like a supported workout CSV…";
  - "Workouts have no names in Shrug" → "Imported workouts have no names";
  - "Search Shrug exercises" → "Search imported exercises".
- Check: `grep -rn '"[^"]*Shrug' WorkoutLogger` must find no user-facing string.

---

## Group B — Redesign
Colours, layout and copy are all in **SPEC §6**. Build the shared pieces first so the later steps reuse them:
- `Theme`: the colour tokens;
- the section label;
- the grouped card;
- the switch row.

### B1. Theme, four tabs, Workouts tab (History merged in)
- The app is **dark only** (`.preferredColorScheme(.dark)`) with the SPEC §6 palette. The accent is lime `#C6F432` and is used only for "do this now": Finish, Save, the current exercise, the rest time, the selected tab and PR marks.
- Tabs: **Workouts, Exercises, Progress, Settings**. Settings uses the gear icon. The History tab is removed.
- Workouts tab, from top to bottom:
  - large title "Workouts";
  - a full-width **Start workout** button, 48 pt tall, accent fill;
  - a row with "From template" and one small pill per template (34 pt);
  - history grouped under **THIS WEEK / LAST WEEK / <Month Year>**.
- History rows are cards. The title is the workout name. The line under it reads `Mon 24/11 · 61 min · 20 sets · 6,140 kg`. If the workout set any PR, add ` · 1 PR` (or `n PRs`) in the accent colour.
- Tapping a row opens the **past workout** screen:
  - back button "Workouts" and an **Edit** button;
  - the name as the title, with `Mon 24/11 · 12:02 – 13:03` under it;
  - a card with **Duration / Sets / Volume**;
  - each exercise as a compact table, with PR marks.
- Swipe to delete works as in A5.

### B2. Full-screen workout with minimise, and the mini-bar
- Starting or resuming a workout opens it **full screen, with no tab bar**:
  - top left, a ⌄ minimise button;
  - top right, **Finish** (accent; grey while there are no sets);
  - the workout name as a big title you edit in place, with no label and the placeholder "Workout";
  - the elapsed time ("38 min") on the right.
- Just started, with no exercises yet: under "Started 12:45" there is one big dashed card with an accent ⊕ and **Add exercise**. The whole card is the button.
- Minimised: a **mini-bar** sits above the tab bar on every tab. It's a rounded card with:
  - a small rest ring on the left;
  - the name, with "38 min · Rest 1:42" under it;
  - a ⌃ chevron.
  
  Tapping it opens the workout again.
- While a workout is open, the Start workout button reads "Workout in progress" in grey and opens it.
- The mini-bar replaces the old "Resume workout" banner. After a relaunch with an unfinished workout, the mini-bar shows.
- Finishing with an empty name still asks for a name, with Skip (SPEC §2).

### B3. Workout in progress: table layout and rest dock
- Each exercise is a section:
  - the name (semibold; **accent** for the current exercise, which is the one with the most recent set);
  - **+ Set** in the accent colour, on the right;
  - a small grey column header **SET · KG · REPS · NOTE**;
  - one 38 pt row per set with a hairline under it. NOTE holds "RIR 1", "Drop" and/or a small accent **PR**.
- Remove "Last: 80×8" everywhere.
- **Quick buttons** (SPEC §3) show only under the current exercise, in a row starting with the word "Repeat".
- Tap a set to edit it in the set pad. Swipe left to delete it, with undo.
- At the bottom, a **dock** with two equal halves:
  - left: the rest box, with a ring, **REST** and the time in the accent colour;
  - right: an outlined **Add exercise** button.
- Tapping the rest box opens the **rest sheet**:
  - a big ring with the time;
  - "Alert at 3:00";
  - **−30 s** and **+30 s**, which move this rest period's alert time;
  - **Skip rest**, which ends this rest period, cancels its alert and its Live Activity, and hides the timer until the next set.
- Pure logic, tested in `RestTimerMath`:
  - ring progress = elapsed ÷ alert time, capped at 1;
  - ±30 s limits: the alert time stays between 0:30 and 10:00, and never goes below the time already elapsed.

### B4. Set pad
- Remove the ± weight buttons and the "Last …" line. Keep the big keypad and the Weight / Reps / RIR fields. Empty fields show "—".
- **Prefill** (pure logic in `SetPlanner`, with tests):
  - **First set of an exercise in this workout:** weight = weight of **set 1 of that exercise's most recent earlier session**. Reps are not filled. That set's reps show as a **grey hint** in the Reps field (e.g. "10"). The cursor starts in Reps.
  - **Later sets in this workout:** weight = the previous set's weight from this workout. Reps are empty with no hint.
  - **Exercise never done before:** everything empty, and the cursor starts in Weight.
- **Save set** stays grey and disabled until weight and reps both have values.
- **×2 button**, left of the Working / Drop toggle:
  - it doubles the current weight field (rounded to 0.01);
  - the hint next to it changes from "One side? Tap ×2" to "Doubled. Saved as the total.";
  - the doubled value is what gets saved;
  - typing in Weight clears the "doubled" state;
  - Settings → "Show ×2 button" hides it.
- Tests: the prefill cases above, and ×2 rounding.

### B5. Exercises, Progress and Settings
- **Exercises tab:**
  - large title, with a round **+** on the right for a new exercise;
  - the search field (A2);
  - a "RECENT FIRST" list card showing each name, with the date it was last used on the right (or nothing if never used), sorted by last used and then by name;
  - archived exercises keep their own section at the bottom;
  - equipment and increment are **hidden** in the list and in the editor, so the editor only edits the name.
- **Progress tab:**
  - an exercise picker pill ("Incline Smith Press ⌄");
  - the metric segmented control, keeping e1RM / Top set / Volume;
  - a chart card with:
    - the current value, large;
    - the change over the selected range, in the accent colour;
    - the line chart (accent line and points);
    - "Best set 82.5 × 8 · Sat 22/11";
    - the 1M–All range picker;
  - then **RECENT PRs**: a list card with the exercise, the date and the set;
  - the training calendar stays below RECENT PRs;
  - the per-exercise screen keeps its full history list.
- **Settings:**
  - **LOGGING**:
    - **Quick buttons**: three small text fields, defaults −1, −2, −3. Each takes 1–9 and shows as "−N". An empty field hides that button.
    - **Show ×2 button**: a switch.
    - Footnote: "Quick buttons add a set with fewer reps. Leave one empty to hide it."
  - **REST TIMER**:
    - **Rest alert**: a switch;
    - **Alert after**: the existing wheel;
    - **Lock screen timer**: a switch, used by C2.
  - **DATA**: **Weekly backup to Files** (C1), then **Export** and **Import** (A6).
  - **APPLE HEALTH**: unchanged, Health build only.
- Tests: parsing the quick buttons (blank, 0, 10, "−2", "2").

---

## Group C — New features

### C1. Weekly automatic backup
- It replaces the weekly backup *reminder* notification. Remove the reminder and its setting.
- The switch is **Weekly backup to Files** and is on by default. Under it: "Last: Sun 23/11", or "Never".
- Each time the app comes to the foreground, if the switch is on and the last backup is 7 or more days old, write a JSON backup in the background. It is the same format as Export → Backup.
  - The file is `WorkoutLogger-backup-YYYY-MM-DD.json` in the app's **Documents** folder.
  - Turn on `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` so the folder appears in Files under *On My iPhone › WorkoutLogger*.
  - Keep the newest **8** files and delete older ones.
- Tell the user, in the step summary: deleting the app deletes this folder. Re-sideloading with the same bundle ID keeps it.
- Pure logic, tested: whether a backup is due (date maths), and which files to prune.

### C2. Lock screen Live Activity (rest timer)
- **First, check the fallback.** The user reported that the lock screen rest notification "is not working". Before building anything, find out why the v1.0 "Rest over" alert might not fire on a real phone:
  - notification permission is never requested, or is requested too late;
  - the alert is not scheduled when the app goes to the background;
  - it is cancelled by mistake;
  - foreground presentation is missing.
  
  Fix what you find and add a test where it's pure logic. Then report what you found.
- Add a Widget Extension target **`RestTimerWidget`** in `project.yml` with bundle ID `com.saad.workoutlogger.RestTimer`. The extension is always built and embedded. The app's code that starts or updates activities is compiled only when the **`LIVEACTIVITY`** flag is set. The no-Live-Activity IPA removes the extension by deleting `Payload/WorkoutLogger.app/PlugIns/` before zipping.
- The `ActivityAttributes` type goes in a file shared by both targets.
- Add `NSSupportsLiveActivities = YES` to the app's Info.plist (Health/Live Activity builds).
- It needs no push and no paid capability. Updates are local only.
- Content:
  - **Lock screen:** "Rest" in small grey, a big count-up time in the accent colour (`Text(timerInterval:countsDown: false)`, so it ticks without the app), and "Alert at 3:00" on the right.
  - **Dynamic Island:** compact, the app icon glyph and the time; minimal, the time; expanded, the same as the lock screen.
- Behaviour:
  - logging a set starts or updates the activity;
  - −30 s / +30 s update "Alert at";
  - Skip, Finish and discarding the workout end it.
- The setting is Settings → **Lock screen timer**. If it's off, or Live Activities aren't available, the app falls back to the existing "Rest over" notification. That alert notification fires in both cases.
- Change `scripts/build-ipas.sh` to produce exactly **three** IPAs, with the same bundle ID so data is kept:
  1. `WorkoutLogger-full.ipa`: `HEALTHKIT` + `LIVEACTIVITY`. **Try this first.**
  2. `WorkoutLogger-live.ipa`: `LIVEACTIVITY` only. Use it if the full one fails to sign or Health fails.
  3. `WorkoutLogger-basic.ipa`: neither flag, with `PlugIns/` removed. This is the last resort.
- Ad-hoc sign the `.appex` **before** the app, and give the app the Health entitlements in build 1 only.
- Like HealthKit, the Live Activity is **unverified with a free Apple ID**. Say so in PROGRESS.md.

### C3. Release v1.1
- Set `MARKETING_VERSION` to 1.1.
- Update PROGRESS.md.
- Build the three IPAs with `scripts/build-ipas.sh` and publish GitHub release **v1.1** with them.
- Give the user the paths, and say to try `WorkoutLogger-full.ipa` first.

---

## Later (v1.2, not now)
- Voice logging: say "eighty kilos, eight reps, RIR one" to log a set, using on-device speech.
- AI features, such as a weekly summary.
