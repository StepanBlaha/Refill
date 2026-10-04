#!/bin/zsh
# Release build → build/Refill-<version>.dmg and build/Refill.zip, plus a .sha256 for each.
# The zip is a ditto archive of Refill.app (the app is the top item, signature included).
# Optional, once you have an Apple Developer account:
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"  → re-sign with hardened runtime
#   NOTARY_PROFILE=refill  (xcrun notarytool store-credentials refill …) → notarize + staple the dmg
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION=$(cat VERSION 2>/dev/null || echo 0.1.0)
mkdir -p build

write_sha() {
  local file="$1" dir name
  dir=$(dirname "$file")
  name=$(basename "$file")
  if command -v shasum >/dev/null 2>&1; then
    ( cd "$dir" && shasum -a 256 "$name" ) > "${file}.sha256"
  else
    ( cd "$dir" && sha256sum "$name" ) > "${file}.sha256"
  fi
}
if [[ -z "${SKIP_BUILD:-}" ]]; then
  xcodegen generate -q
  xcodebuild -project Refill.xcodeproj -scheme Refill -configuration Release \
    -derivedDataPath build/xcode -allowProvisioningUpdates \
    MARKETING_VERSION="$VERSION" build > build/release.log 2>&1 || { tail -20 build/release.log; exit 1; }
fi
APP=build/xcode/Build/Products/Release/Refill.app

if [[ -n "${DEVELOPER_ID:-}" ]]; then
  codesign --force --deep --options runtime --timestamp -s "$DEVELOPER_ID" "$APP"
elif ! codesign --verify "$APP" >/dev/null 2>&1; then
  # Nothing has signed the app. Ad-hoc sign it so the zip carries a signature.
  # --deep covers the widget extension nested inside Refill.app.
  codesign --force --deep --sign - "$APP"
fi

STAGE=build/dmg; rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"; ln -s /Applications "$STAGE/Applications"
DMG="build/Refill-$VERSION.dmg"; rm -f "$DMG"
hdiutil create -volname "Refill $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

if [[ -n "${DEVELOPER_ID:-}" ]]; then codesign -s "$DEVELOPER_ID" --timestamp "$DMG"; fi
# Stable asset names. The release workflow uploads these, not the versioned dmg,
# so latest/download/Refill.dmg and Refill.zip keep working. The versioned dmg stays local.
cp "$DMG" build/Refill.dmg
# Same bytes under the stable zip name. ditto keeps the code signature, which
# `zip -r` does not. --keepParent puts Refill.app at the top of the archive.
ZIP="build/Refill.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
  # Stapling changes the dmg. The checksums are written after this.
  cp "$DMG" build/Refill.dmg
fi
write_sha build/Refill.dmg
write_sha build/Refill.zip
echo "Built $DMG ($(du -h "$DMG" | cut -f1)) and $ZIP ($(du -h "$ZIP" | cut -f1))"
[[ -z "${DEVELOPER_ID:-}" ]] && echo "Note: not Developer ID signed. Homebrew and scripts/install.sh clear quarantine. By hand: System Settings → Privacy & Security → Open Anyway."
