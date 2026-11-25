#!/bin/zsh
# Builds three IPAs for Sideloadly into ~/Desktop/ipa (and build/). All use the same bundle ID
# (com.saad.workoutlogger), so installing any of them over another keeps the data.
#   WorkoutLogger-full.ipa   HEALTHKIT + LIVEACTIVITY. Try this first.
#   WorkoutLogger-live.ipa   LIVEACTIVITY only. Use it if the full one fails to sign or Health fails.
#   WorkoutLogger-basic.ipa  neither flag, PlugIns/ removed, unsigned. Last resort.
# The widget extension (.appex) is ad-hoc signed before the app; only the full build gives the
# app the HealthKit entitlement (so Sideloadly can keep it when it re-signs).
set -euo pipefail
setopt null_glob
cd "$(dirname "$0")/.."
OUT=~/Desktop/ipa
mkdir -p build "$OUT"
APP=Payload/WorkoutLogger.app

archive() { # $1 = name, $2 = compilation conditions
  xcodebuild -project WorkoutLogger.xcodeproj -scheme WorkoutLogger \
    -configuration Release -destination 'generic/platform=iOS' \
    -archivePath "build/$1.xcarchive" archive \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS=$2" -quiet
}

package() { # $1 = name
  rm -rf "build/$1-Payload" && mkdir -p "build/$1-Payload/Payload"
  cp -R "build/$1.xcarchive/Products/Applications/WorkoutLogger.app" "build/$1-Payload/Payload/"
}

sign_appex() { # $1 = name
  for appex in "build/$1-Payload/$APP"/PlugIns/*.appex; do
    codesign --force --sign - "$appex"
  done
}

zipit() { # $1 = name
  (cd "build/$1-Payload" && rm -f "../WorkoutLogger-$1.ipa" && zip -qr "../WorkoutLogger-$1.ipa" Payload)
  cp "build/WorkoutLogger-$1.ipa" "$OUT/"
}

rm -f "$OUT"/WorkoutLogger-*.ipa

# 1. Full: Health + Live Activity.
archive full "HEALTHKIT LIVEACTIVITY"
package full
sign_appex full
codesign --force --sign - --entitlements WorkoutLogger/WorkoutLogger-Health.entitlements "build/full-Payload/$APP"
zipit full

# 2. Live Activity only (no Health entitlement).
archive live "LIVEACTIVITY"
package live
sign_appex live
codesign --force --sign - "build/live-Payload/$APP"
zipit live

# 3. Basic: no flags, no extension, unsigned.
archive basic ""
package basic
rm -rf "build/basic-Payload/$APP/PlugIns"
zipit basic

ls -lh "$OUT"
