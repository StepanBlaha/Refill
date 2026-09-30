#!/bin/zsh
# Release build → Refill-<version>.dmg (drag-to-Applications).
# Optional, once you have an Apple Developer account:
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"  → re-sign with hardened runtime
#   NOTARY_PROFILE=refill  (xcrun notarytool store-credentials refill …) → notarize + staple
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION=$(cat VERSION 2>/dev/null || echo 0.1.0)
xcodegen generate -q
xcodebuild -project Refill.xcodeproj -scheme Refill -configuration Release \
  -derivedDataPath build/xcode -allowProvisioningUpdates \
  MARKETING_VERSION="$VERSION" build > build/release.log 2>&1 || { tail -20 build/release.log; exit 1; }
APP=build/xcode/Build/Products/Release/Refill.app

if [[ -n "${DEVELOPER_ID:-}" ]]; then
  codesign --force --deep --options runtime --timestamp -s "$DEVELOPER_ID" "$APP"
fi

STAGE=build/dmg; rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"; ln -s /Applications "$STAGE/Applications"
DMG="build/Refill-$VERSION.dmg"; rm -f "$DMG"
hdiutil create -volname "Refill $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

if [[ -n "${DEVELOPER_ID:-}" ]]; then codesign -s "$DEVELOPER_ID" --timestamp "$DMG"; fi
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
fi
echo "Built $DMG ($(du -h "$DMG" | cut -f1))"
[[ -z "${DEVELOPER_ID:-}" ]] && echo "Note: not Developer ID signed; other Macs will need right-click → Open."
