#!/usr/bin/env bash
# Builds MDReader (Release, so speech generation runs at full speed) into dist/MDReader.app and opens it.
#
#   ./Scripts/build.sh               build, open
#   ./Scripts/build.sh --no-launch   build only
#
# Signs as the project does (automatically, with your Apple Development certificate). Without one,
# run with ADHOC=1 for an ad-hoc signed build.
set -euo pipefail
cd "$(dirname "$0")/.."

OVERRIDES=()
if [[ "${ADHOC:-}" == 1 ]]; then
  # The hardened runtime's library validation refuses ad-hoc signed frameworks such as Sparkle.
  OVERRIDES=(CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO)
fi

echo "Building MDReader… (the first build compiles MLX and takes a few minutes)"
xcodebuild -project MDReader.xcodeproj -scheme MDReader -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath .build/xcode \
  -skipMacroValidation -skipPackagePluginValidation -quiet \
  ${OVERRIDES[@]+"${OVERRIDES[@]}"} build

rm -rf dist/MDReader.app
mkdir -p dist
ditto .build/xcode/Build/Products/Release/MDReader.app dist/MDReader.app
echo "Built dist/MDReader.app"

if [[ "${1:-}" != "--no-launch" ]]; then
  # Quit a running copy and wait until it's gone; opening while it shuts down fails with error -600.
  if pkill -x MDReader; then
    while pgrep -x MDReader >/dev/null; do sleep 0.2; done
  fi
  open dist/MDReader.app
  echo "Opened — look for the MDReader page icon in the menu bar."
fi
