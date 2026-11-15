# PROGRESS

_Last updated: 2026-11-16_

## Completed steps (SPEC.md build order)
1. Project setup (XcodeGen, SwiftData models, tabs, git) ✅
2. Exercise library CRUD: fixed equipment enum, unique names, archive instead of delete when there is history ✅
3. Active workout: compact set rows, −1/−2/−3 chips, "+ Add Set" keypad sheet (content-sized), undo toast, save after every change with visible save errors, keep-awake, resume banner (shown on tabs other than Workout) ✅
4. Rest timer (count-up, from last set) + one local notification per rest period; settings wheel 0:30–10:00 ✅
5. History (name, dd/MM, sets · duration · load), edit past workouts incl. date/time, delete with undo, rename, templates ✅
6. Progress: e1RM / Top set / Volume graphs with 1M–All ranges, PR badges (weight, reps), Monday-first training calendar ✅
7. Shrug CSV import from the real export (Fixtures/shrug_sample.csv): mapping (keep / rename / merge), lb→kg or "already kg" per exercise, timed rows skipped, batched with progress, summary, idempotent ✅
8. JSON backup export/import (skip existing ids, never overwrite), CSV export, weekly backup reminder (Sun 19:00) ✅
9. Apple Health: Settings toggle + `HEALTHKIT` compile flag; writes Traditional Strength Training (start → finish) ✅
10. 95 unit tests passing; two IPAs built and published ✅

Muscle groups were removed from the app (now out of scope in SPEC.md).

## Current state
- Release **v1.0**: https://github.com/S3oody8/Gym-App/releases/tag/v1.0
  - `WorkoutLogger-health.ipa`: HealthKit compiled in; ad-hoc signed only to embed the HealthKit entitlement.
  - `WorkoutLogger-nohealth.ipa`: unsigned, no HealthKit.
- Rebuild both with `scripts/build-ipas.sh` (outputs to `~/Desktop/ipa/` and `build/`).

## Open issues / unverified
- **HealthKit on a free Apple ID through Sideloadly is unverified.** If the health IPA fails to sign or Health access fails, use the no-health IPA. Both use the same bundle ID, so data is kept.
- Not tested by hand (the simulator can't tap): set entry and swipes, the Files save/open dialogs, the Shrug file picker, History rename, rest alert and backup reminder banners on a real device, Health write.
- Dynamic Type at the largest sizes hasn't been checked on the keypad sheet or the set rows.
- Exercises created by the Shrug import default to Machine equipment and a 2.5 kg increment. Adjust them in Exercises.
- Shrug workouts have no per-set times, so their duration isn't shown.
- Not built: optional bulk rename in History (select mode → rename all).
- Debug-only screenshot scenarios (`DebugScenario`, `DebugSeeder`) are compiled out of Release.

## Next action
Install `WorkoutLogger-health.ipa` with Sideloadly. If signing fails or Health doesn't work, install `WorkoutLogger-nohealth.ipa`. Then run Settings → Data → Import from Shrug on the phone with the real export, and report anything that looks wrong.
