#!/usr/bin/env bash
# Builds MDReader (Release, so speech generation runs at full speed) into dist/MDReader.app and opens it.
#
#   ./Scripts/build.sh               build, open
#   ./Scripts/build.sh --no-launch   build only
#
# Signs as the project's Release configuration does (Developer ID). Without that certificate,
# run with ADHOC=1 for an ad-hoc signed build.
set -euo pipefail
cd "$(dirname "$0")/.."

OVERRIDES=()
if [[ "${ADHOC:-}" == 1 ]]; then
  # The hardened runtime's library validation refuses ad-hoc signed frameworks such as Sparkle.
  OVERRIDES=(CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO)
fi

xcodebuild -project MDReader.xcodeproj -scheme MDReader -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath .build/xcode \
  -skipMacroValidation -skipPackagePluginValidation -quiet \
  ${OVERRIDES[@]+"${OVERRIDES[@]}"} build

rm -rf dist/MDReader.app
mkdir -p dist
ditto .build/xcode/Build/Products/Release/MDReader.app dist/MDReader.app
echo "Built dist/MDReader.app"

if [[ "${1:-}" != "--no-launch" ]]; then
  pkill -x MDReader 2>/dev/null || true
  open dist/MDReader.app
  echo "Opened — look for the speaker icon in the menu bar."
fi
