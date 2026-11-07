#!/usr/bin/env bash
# Builds a release of MDReader the way Xcode's Organizer does — archive, then export for Developer ID —
# then notarizes and staples it, and writes the Sparkle update feed. Leaves dist/MDReader-<version>.zip
# and dist/appcast.xml; publishing them to GitHub is left to you (the command is printed at the end).
#
# One-time setup — store notarization credentials in your keychain (use an app-specific password
# from account.apple.com for the Apple ID of your developer team):
#
#   xcrun notarytool store-credentials MDReader --apple-id <your Apple ID> --team-id K8AK936KU6
#
# Updates are signed with the Sparkle EdDSA key in your keychain (created once with Sparkle's
# generate_keys; its public half is SUPublicEDKey in Info.plist).
set -euo pipefail
cd "$(dirname "$0")/.."

# Read the whole script before running it, so editing it mid-run can't derail the run.
{

PROFILE="${NOTARY_PROFILE:-MDReader}"
REPO="push1kb/MDReader"
ARCHIVE="dist/MDReader.xcarchive"
APP="dist/MDReader.app"

if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
  echo "No notarytool profile named '$PROFILE'. Run the one-time setup at the top of this script." >&2
  exit 1
fi

rm -rf "$ARCHIVE" dist/export "$APP"
echo "Archiving… (a clean Release build of MLX takes a few minutes)"
xcodebuild -project MDReader.xcodeproj -scheme MDReader -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath .build/xcode \
  -skipMacroValidation -skipPackagePluginValidation -quiet \
  -archivePath "$ARCHIVE" archive
echo "Exporting for Developer ID…"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath dist/export \
  -exportOptionsPlist Scripts/ExportOptions.plist -quiet
ditto dist/export/MDReader.app "$APP"
rm -rf dist/export

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ZIP="dist/MDReader-$VERSION.zip"
echo "Notarizing MDReader $VERSION… (Apple usually takes a few minutes)"

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
echo "Stapling the notarization ticket…"
xcrun stapler staple "$APP"

# Re-zip so the download carries the stapled ticket and opens offline.
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute --verbose "$APP"

# The update feed. Sparkle's tools come with the Sparkle package that Xcode resolved.
echo "Writing the update feed…"
SPARKLE_BIN="$(find .build/xcode/SourcePackages/artifacts -type d -path '*Sparkle/bin' | head -1)"
UPDATES="dist/updates"
rm -rf "$UPDATES" && mkdir -p "$UPDATES"
cp "$ZIP" "$UPDATES/"
"$SPARKLE_BIN/generate_appcast" --download-url-prefix "https://github.com/$REPO/releases/download/v$VERSION/" "$UPDATES"
cp "$UPDATES/appcast.xml" dist/appcast.xml

echo
echo "Release ready: $ZIP and dist/appcast.xml"
echo "Publish it with:"
echo "  gh release create v$VERSION $ZIP dist/appcast.xml --repo $REPO --title \"MDReader $VERSION\" --notes \"…\""
exit
}
