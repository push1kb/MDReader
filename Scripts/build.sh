#!/usr/bin/env bash
# Builds dist/MDReader.app and opens it.
#
#   ./Scripts/build.sh               build, ad-hoc sign, open
#   ./Scripts/build.sh --no-launch   build and sign only
#
# Set SIGN_IDENTITY to sign with a real certificate (Scripts/release.sh does this).
# xcodebuild, not `swift build`, because only xcodebuild compiles MLX's Metal shaders.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-Release}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
DERIVED=".build/xcode"
PRODUCTS="$DERIVED/Build/Products/$CONFIG"
APP="dist/MDReader.app"

xcodebuild -scheme MDReader -configuration "$CONFIG" \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED" \
  -skipMacroValidation -skipPackagePluginValidation \
  -quiet build

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$PRODUCTS/MDReader" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns Resources/PrivacyInfo.xcprivacy "$APP/Contents/Resources/"
# SwiftPM resource bundles, including MLX's compiled Metal library.
cp -R "$PRODUCTS"/*.bundle "$APP/Contents/Resources/"
# Sparkle, for updates. The app has network access itself, so Sparkle's downloader service isn't needed.
mkdir -p "$APP/Contents/Frameworks"
ditto "$PRODUCTS/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
rm -rf "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Sign inside-out: Sparkle's helpers, the framework, resource bundles, then the app itself.
# Ad-hoc builds skip the hardened runtime: its library validation rejects ad-hoc signed frameworks.
sign() { codesign --force --timestamp=none --sign - "$@"; }
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  sign() { codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$@"; }
fi
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
sign "$SPARKLE/XPCServices/Installer.xpc" "$SPARKLE/Autoupdate" "$SPARKLE/Updater.app"
sign "$APP/Contents/Frameworks/Sparkle.framework"
for bundle in "$APP"/Contents/Resources/*.bundle; do sign "$bundle"; done
sign --entitlements Resources/MDReader.entitlements "$APP"
echo "Built $APP"

if [[ "${1:-}" != "--no-launch" ]]; then
  pkill -x MDReader 2>/dev/null || true
  open "$APP"
  echo "Opened — look for the speaker icon in the menu bar."
fi
