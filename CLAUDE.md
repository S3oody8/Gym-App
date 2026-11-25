# CLAUDE.md — Working rules for this repo

SPEC.md is **what** to build. This file is **how** to work. Read both fully at the start of every session.

## 1. Source of truth
- SPEC.md is the source of truth. Do not add features listed under "Out of scope", and do not invent features.
- If the spec is ambiguous or contradicts itself, stop and ask before building. Do not guess.
- When you make an assumption that the spec doesn't cover, list it in your end-of-step summary.

## 2. Environment (important)
- Machine: Scaleway cloud Mac mini (M1 or M2, 8 GB+ RAM), rented by the day. The user connects by remote desktop and often drives you from his phone, so he cannot easily look at the simulator.
- The machine is **wiped when deleted**. Anything not pushed to GitHub is lost.
- 8 GB RAM is tight:
  - Build and test from the CLI with `xcodebuild`. Do not open the Xcode GUI.
  - Only boot a simulator when running tests or when the user asks to see the app. Run `xcrun simctl shutdown all` afterwards.
  - Never run two builds at once.

## 3. Project setup
- Use **XcodeGen** (`brew install xcodegen`) to define the project in `project.yml`, then run `xcodegen generate`. Commit `project.yml`. Do not hand-edit `.pbxproj`. Regenerate after adding files or targets.
- Targets: `WorkoutLogger` (iOS app), `WorkoutLoggerTests` (unit tests), and from v1.1 step C2 `RestTimerWidget` (widget extension for the rest-timer Live Activity, bundle ID `com.saad.workoutlogger.RestTimer`).
- Bundle ID: `com.saad.workoutlogger`. **Never change it**: changing it wipes all data on the iPhone when re-sideloading.
- Deployment target: iOS 18.0. Device family: iPhone only. Orientation: portrait only.
- Do **not** add iCloud, Push Notifications or any capability that needs a paid Apple Developer account. Local notifications are fine (no capability needed). HealthKit: see SPEC section 9.
- `.gitignore`: DerivedData, build/, *.xcuserstate, xcuserdata/, .DS_Store, *.ipa.

## 4. Build and test commands
First find the simulator: `xcrun simctl list devices available`. Use the **newest available iPhone Pro** simulator (e.g. iPhone 18 Pro); if there is no Pro model, use the newest iPhone. Substitute its name (or `id=<UDID>`) in the commands below.

```bash
# Build (no signing needed for the simulator)
xcodebuild -project WorkoutLogger.xcodeproj -scheme WorkoutLogger \
  -destination 'platform=iOS Simulator,name=<newest iPhone Pro>' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO -quiet

# Tests
xcodebuild -project WorkoutLogger.xcodeproj -scheme WorkoutLogger \
  -destination 'platform=iOS Simulator,name=<newest iPhone Pro>' test -quiet
```
- On a failed build, read the errors, fix them and rebuild until it's clean. Treat new warnings as things to fix.
- Screenshots: if the user asks to see a screen, boot the simulator, install, launch and capture it with `xcrun simctl io booted screenshot ~/Desktop/<name>.png`, then shut the simulator down.

## 5. Code rules
- SwiftUI + SwiftData + Swift Charts. MVVM. No third-party packages unless you ask first.
- Every SwiftData model has `id: UUID`. Weights are stored as `Double` in kg.
- Keep pure logic (e1RM, PR detection, weekly volume, CSV parsing, JSON export/import) in plain Swift types with no UI. Those parts must be unit tested.
- One type per file. Folder layout: `Models/`, `ViewModels/`, `Views/<Feature>/`, `Services/`, `Utilities/`.
- Never delete or rename a model property without a SwiftData migration plan. Ask first. Real workout data is on the phone. v1.1 needs **no** model changes: settings go in UserDefaults.
- Persist after every set change (crash safety, SPEC section 2).

## 6. Workflow
- v1.0 is done. For v1.1, work through **PLAN-v1.1.md** (A1 → C3) **one step at a time**. Read SPEC.md, this file and PLAN-v1.1.md fully before starting.
- After each step: build clean → run tests → `git add -A && git commit -m "<step>: <what>"` → `git push`.
- Then **stop** and give a short summary: what's done, assumptions made, and what's next. Wait for "continue".
- Never show the word "Shrug" in the app's UI (labels, titles, messages, errors, prompts). Internal type names may keep it.

## 7. End of session (the user will say "wrap up")
1. Build and test pass.
2. Commit and push everything. Confirm `git status` is clean and the branch is up to date with origin.
3. Write `PROGRESS.md`: completed steps, current step, open issues, next action. Commit and push it.
4. Run `xcrun simctl shutdown all`.

## 8. Final build for the iPhone (only when the user asks)
Produce an **unsigned IPA** for Sideloadly (it re-signs with the user's Apple ID):
```bash
xcodebuild -project WorkoutLogger.xcodeproj -scheme WorkoutLogger \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/WorkoutLogger.xcarchive archive \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
mkdir -p build/Payload
cp -R build/WorkoutLogger.xcarchive/Products/Applications/WorkoutLogger.app build/Payload/
cd build && zip -qr WorkoutLogger.ipa Payload
```
Do not commit the IPA. Tell the user its path so he can download it.
