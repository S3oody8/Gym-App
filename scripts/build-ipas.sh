#!/bin/zsh
# Builds two IPAs for Sideloadly into ~/Desktop/ipa (and build/):
#   WorkoutLogger-nohealth.ipa  unsigned, no HealthKit code or entitlement (CLAUDE.md section 8)
#   WorkoutLogger-health.ipa    HEALTHKIT compiled in; ad-hoc signed only to carry the
#                               HealthKit entitlement so Sideloadly can keep it when it re-signs
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=~/Desktop/ipa
mkdir -p build "$OUT"

archive() { # $1 = name, $2 = extra compilation conditions
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

zipit() { # $1 = name
  (cd "build/$1-Payload" && rm -f "../WorkoutLogger-$1.ipa" && zip -qr "../WorkoutLogger-$1.ipa" Payload)
  cp "build/WorkoutLogger-$1.ipa" "$OUT/"
}

archive nohealth ""
package nohealth
zipit nohealth

archive health "HEALTHKIT"
package health
codesign --force --sign - --entitlements WorkoutLogger/WorkoutLogger-Health.entitlements \
  "build/health-Payload/Payload/WorkoutLogger.app"
zipit health

ls -lh "$OUT"
