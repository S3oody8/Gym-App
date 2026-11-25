#!/bin/zsh
# Regenerate, build and test on the newest iPhone Pro simulator, then shut simulators down.
# Usage: scripts/check.sh [build|test|all]   (default: all)
set -u
cd "$(dirname "$0")/.."
DEST="platform=iOS Simulator,name=${SIM_NAME:-iPhone 18 Pro}"
MODE="${1:-all}"
xcodegen generate -q >/dev/null || exit 1
if [[ "$MODE" == build || "$MODE" == all ]]; then
  xcodebuild -project WorkoutLogger.xcodeproj -scheme WorkoutLogger -destination "$DEST" \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO -quiet 2>&1 | grep -E "error|warning:" | sort -u | head -40
  [[ ${pipestatus[1]} -eq 0 ]] || { echo "BUILD FAILED"; exit 1; }
  echo "BUILD OK"
fi
if [[ "$MODE" == test || "$MODE" == all ]]; then
  xcodebuild -project WorkoutLogger.xcodeproj -scheme WorkoutLogger -destination "$DEST" test 2>&1 \
    | grep -E "error:|warning:|failed \(|Executed [0-9]+ tests.*seconds$|TEST (SUCCEEDED|FAILED)" | grep -v appintents | sort -u | tail -4
  xcrun simctl shutdown all
fi
