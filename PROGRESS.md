# PROGRESS

_Last updated: 2026-11-26_

## v1.0 (done)
Steps 1–10 of the original build order: project setup, exercise library, active workout, rest
timer, history, progress graphs and PRs, workout CSV import, JSON/CSV backup, Apple Health,
IPAs. Release **v1.0**: https://github.com/S3oody8/Gym-App/releases/tag/v1.0

## v1.1 (PLAN-v1.1.md), all steps done
- A1 Finish time = time of the last set ✅
- A2 Flexible exercise search (any word order, partial words, case/accents), prefix ranking, highlighted matches ✅
- A3 Create exercise from the picker's search; the set pad opens straight after adding ✅
- A4 Workout name saved 0.5 s after typing stops (and on Return, leaving, Finish) ✅
- A5 Swipe-to-delete in history, no dialog, undo toast ✅
- A6 Settings → Data: Export / Import menus; no "Shrug" in any UI string ✅
- B1 Dark theme, four tabs, Workouts tab with history, past workout screen ✅
- B2 Full-screen workout with minimise, mini-bar above the tab bar ✅
- B3 Table layout, current exercise, Repeat quick buttons, rest dock and rest sheet (±30 s, Skip) ✅
- B4 Set pad: prefill rules, grey reps hint, ×2, Save disabled until weight and reps ✅
- B5 Exercises tab, Progress tab (chart card, best set, RECENT PRs, calendar), Settings ✅
- C1 Weekly automatic backup to Files (newest 8 kept) ✅
- C2 Rest notification fixes + lock screen Live Activity (RestTimerWidget extension) ✅
- C3 Version 1.1, three IPAs, GitHub release ✅ (see "Current state")

Tests: 139 unit tests passing.

## v1.1.1 (PLAN-v1.1.1.md), in progress
- F1 Lag fix ✅ (done first, as the plan says). Test IPAs are in `~/Desktop/ipa` (version still 1.1 (2)).
  - The PR detector is now one pass (was O(n²)), checked against the old algorithm on random sets.
  - A `PRCache` holds PR badges, PR counts, RECENT PRs, last-used dates and history row summaries. It is
    invalidated by `WorkoutStore`, imports, JSON restore and the seed, and built on a background
    `@ModelActor` at launch.
  - Timer `TimelineView`s now wrap only the ticking text and ring.
  - Timings on the simulator with the `largeHistory` seed (300 workouts, 6,000 sets):

    | | before | after |
    |---|---|---|
    | History tab PR counts, paid on every redraw | ~990 ms | 0 after the build (warm reads ~0.01 ms) |
    | Full cache build, once per launch, background | n/a | ~150–180 ms |
    | One exercise's badges after logging a set | ~22 ms on every card redraw | ~10–12 ms, once |
- Next: the user tests the lag on the phone, then F0 (folders), F2 + F3, F4, F5, F6, F7, F8 (ask for CSV lines first), release 1.1.1.

Tests: 150 unit tests passing.

## Current state
- Release **v1.1**: https://github.com/S3oody8/Gym-App/releases/tag/v1.1
  - `WorkoutLogger-full.ipa`: HealthKit + Live Activity; widget and app ad-hoc signed, app carries the HealthKit entitlement. **Try first.**
  - `WorkoutLogger-live.ipa`: Live Activity only; widget and app ad-hoc signed, no Health entitlement.
  - `WorkoutLogger-basic.ipa`: no flags, no widget extension, unsigned.
  - The same three files are also in `~/Desktop/ipa/` on the build Mac (lost when the Mac is deleted).
- Release **v1.0**: https://github.com/S3oody8/Gym-App/releases/tag/v1.0

Rebuild the IPAs with `scripts/build-ipas.sh` (writes to `~/Desktop/ipa/` and `build/`).
Build and test with `scripts/check.sh` (`build`, `test` or both).

## Open issues / unverified
- **HealthKit and the Live Activity are unverified with a free Apple ID through Sideloadly.**
  Try `WorkoutLogger-full.ipa` first. If it fails to sign or Health fails, use
  `WorkoutLogger-live.ipa`. If the Live Activity also causes trouble, use
  `WorkoutLogger-basic.ipa` (no extension). All three use the same bundle ID, so data is kept.
- The "Rest over" notification fires in every build, with or without the Live Activity.
- The weekly backup folder (Files › On My iPhone › WorkoutLogger) is deleted if the app is
  deleted. Re-sideloading over the existing app keeps it.
- Not tested by hand (the simulator can't be tapped from here): the new screens and swipes,
  the set pad, the rest sheet, the mini-bar, the Live Activity, the Files folder, and the rest
  alert on a real lock screen.
- Rest alert investigation (C2): no code path that drops the alert was found. Changes made:
  permission is now also requested when an alert is scheduled and it was never asked; the
  pending alert and Live Activity are re-synced when the app goes to the background or comes
  back; the rest sheet warns when notifications are turned off. The screen is kept awake during
  a workout, so the phone only locks when you lock it. If the alert still doesn't show on the
  lock screen, check iOS Settings → Notifications → WorkoutLogger (Lock Screen, Sounds) and any
  Focus or Scheduled Summary that might hold it back.
- Editing or deleting sets of a past workout does not recalculate its stored finish time.
- Debug-only screenshot scenarios (`DebugScenario`, `DebugSeeder`) are compiled out of Release.

## Next action
Install `WorkoutLogger-full.ipa` with Sideloadly and try a workout: the set pad, Repeat
buttons, rest sheet, minimise/mini-bar, the lock screen timer and the "Rest over" alert.
Report anything that looks wrong. v1.2 (voice logging, AI) is planned but not started.
