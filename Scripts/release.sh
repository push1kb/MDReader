#!/usr/bin/env bash
# Builds a release of MDReader: signed with your Developer ID, notarized by Apple and stapled,
# zipped as dist/MDReader-<version>.zip, plus the Sparkle update feed dist/appcast.xml.
# Publishing both to GitHub is left to you; the command is printed at the end.
#
# One-time setup — store notarization credentials in your keychain (use an app-specific password
# from appleid.apple.com):
#
#   xcrun notarytool store-credentials MDReader --apple-id <your Apple ID> --team-id <your team ID>
#
# Updates are signed with the Sparkle EdDSA key in your keychain (created once with Sparkle's
# generate_keys; its public half is SUPublicEDKey in Info.plist).
#
# Override the defaults with SIGN_IDENTITY and NOTARY_PROFILE.
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning \
  | grep -m1 -o '"Developer ID Application: [^"]*"' | tr -d '"' || true)}"
PROFILE="${NOTARY_PROFILE:-MDReader}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
REPO="push1kb/MDReader"
APP="dist/MDReader.app"
ZIP="dist/MDReader-$VERSION.zip"

if [[ -z "$IDENTITY" ]]; then
  echo "No 'Developer ID Application' certificate found in your keychain." >&2
  exit 1
fi

echo "Signing MDReader $VERSION as: $IDENTITY"
SIGN_IDENTITY="$IDENTITY" ./Scripts/build.sh --no-launch
codesign --verify --strict --deep "$APP"

if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
  echo "Signed, but not notarized: no notarytool profile named '$PROFILE'." >&2
  echo "Run the one-time setup at the top of this script, then run it again." >&2
  exit 1
fi

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"

# Re-zip so the download carries the stapled ticket and opens offline.
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute --verbose "$APP"

# The update feed. Sparkle's tools come with the Sparkle package that xcodebuild resolved.
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
