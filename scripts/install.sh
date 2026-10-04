#!/bin/bash
# Install the latest Refill release into /Applications and open it.
#
#   curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/install.sh | bash
#
# Downloads Refill.zip from the latest GitHub release, checks its sha256, replaces
# /Applications/Refill.app, clears the quarantine flag, and launches Refill.
# Release 0.1.1 has no zip, so that release installs Refill.dmg instead and checks
# the sha256 GitHub publishes for the file.
#
# sudo is used only when /Applications is not writable.
# macOS only. The system bash (3.2) is enough.
set -euo pipefail

REPO="StepanBlaha/Refill"
API="https://api.github.com/repos/${REPO}/releases/latest"
DEST="/Applications/Refill.app"
BUNDLE_ID="cz.stepanblaha.refill"

die() {
  echo "error: $*" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<EOF
Install Refill from the latest GitHub release.

  curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/install.sh | bash

The script downloads Refill.zip, checks the sha256, installs to /Applications
(replacing the copy already there), runs xattr -dr com.apple.quarantine, and
opens the app. It asks for an administrator password only when /Applications
is not writable.
EOF
  exit 0
fi

[[ "$(uname -s)" == "Darwin" ]] || die "Refill is a macOS app. This installer only runs on a Mac."
command -v curl >/dev/null 2>&1 || die "curl is required."
command -v shasum >/dev/null 2>&1 || die "shasum is required."
command -v ditto >/dev/null 2>&1 || die "ditto is required."

TMP=$(mktemp -d "${TMPDIR:-/tmp}/refill-install.XXXXXX")
MOUNT=""
cleanup() {
  if [[ -n "$MOUNT" ]]; then
    hdiutil detach "$MOUNT" -quiet >/dev/null 2>&1 || hdiutil detach "$MOUNT" -force >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

# Prints one row per field the installer needs:
#   TAG<tab>v0.1.1
#   ASSET<tab>Refill.zip<tab>sha256:<hex>     (digest may be empty)
# The program is passed as an argument (not awk -f -) so BSD awk on macOS can run it.
parse_release() {
  awk '
function pick(obj, key,    re, i, n, val) {
  re = "\"" key "\""
  if (!match(obj, re)) return ""
  i = RSTART + RLENGTH
  n = length(obj)
  while (i <= n && substr(obj, i, 1) ~ /[ \t\r\n]/) i++
  if (substr(obj, i, 1) != ":") return ""
  i++
  while (i <= n && substr(obj, i, 1) ~ /[ \t\r\n]/) i++
  if (substr(obj, i, 1) != "\"") return ""
  val = substr(obj, i + 1)
  if (match(val, /^[^"\\]*/)) return substr(val, 1, RLENGTH)
  return ""
}
function walk(json,    i, n, c, depth, in_str, esc, start, obj, tag) {
  n = length(json)
  tag = pick(json, "tag_name")
  if (tag != "") printf "TAG\t%s\n", tag
  i = index(json, "\"assets\":")
  if (i == 0) return
  i += 9
  while (i <= n && substr(json, i, 1) ~ /[ \t\r\n]/) i++
  if (substr(json, i, 1) != "[") return
  i++
  depth = 0
  in_str = 0
  esc = 0
  start = 0
  for (; i <= n; i++) {
    c = substr(json, i, 1)
    if (in_str) {
      if (esc) esc = 0
      else if (c == "\\") esc = 1
      else if (c == "\"") in_str = 0
      continue
    }
    if (c == "\"") { in_str = 1; continue }
    if (c == "{") {
      if (depth == 0) start = i
      depth++
      continue
    }
    if (c == "}") {
      depth--
      if (depth == 0 && start > 0) {
        obj = substr(json, start, i - start + 1)
        if (index(obj, "\"browser_download_url\"") > 0) {
          printf "ASSET\t%s\t%s\n", pick(obj, "name"), pick(obj, "digest")
        }
        start = 0
      }
      continue
    }
    if (c == "]" && depth == 0) break
  }
}
{ json = json $0 "\n" }
END { walk(json) }
' "$1"
}

download_ok() {
  local url="$1" dest="$2" code
  code=$(curl -sS -L --retry 3 --retry-delay 1 -o "$dest" -w '%{http_code}' "$url" || true)
  if [[ "$code" == "200" && -s "$dest" ]]; then
    return 0
  fi
  rm -f "$dest"
  return 1
}

echo "Looking up the latest Refill release..."
curl -fsSL --retry 3 \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: refill-install" \
  -o "$TMP/release.json" \
  "$API"

TAG=""
HAS_ZIP=0
HAS_DMG=0
ZIP_DIGEST=""
DMG_DIGEST=""
# Read the parser output from a file. A heredoc would expand $(...) inside a
# malicious tag or digest before we get a chance to reject it.
parse_release "$TMP/release.json" > "$TMP/assets.tsv"
while IFS=$(printf '\t') read -r kind name digest; do
  case "$kind" in
    TAG) TAG="$name" ;;
    ASSET)
      case "$name" in
        Refill.zip) HAS_ZIP=1; ZIP_DIGEST="$digest" ;;
        Refill.dmg) HAS_DMG=1; DMG_DIGEST="$digest" ;;
      esac
      ;;
  esac
done < "$TMP/assets.tsv"
[[ -n "$TAG" ]] || die "Could not read the latest release."

case "$TAG" in
  v[0-9]*) ;;
  *) die "Unexpected release tag: ${TAG:-none}" ;;
esac
case "$TAG" in
  *[!0-9A-Za-z._+-]*) die "Refusing release tag: $TAG" ;;
esac

if [[ "$HAS_ZIP" -eq 1 ]]; then
  ASSET="Refill.zip"
  DIGEST="$ZIP_DIGEST"
elif [[ "$HAS_DMG" -eq 1 ]]; then
  ASSET="Refill.dmg"
  DIGEST="$DMG_DIGEST"
  echo "This release has no Refill.zip. Installing the disk image instead."
else
  die "The latest release has neither Refill.zip nor Refill.dmg."
fi

BASE="https://github.com/${REPO}/releases/download/${TAG}"
ARCHIVE="$TMP/$ASSET"
echo "Downloading ${ASSET} from ${TAG}..."
curl -fL --retry 3 --retry-delay 1 -o "$ARCHIVE" "${BASE}/${ASSET}"
[[ -s "$ARCHIVE" ]] || die "The download was empty."

FILE_SUM=""
API_SUM=""
if download_ok "${BASE}/${ASSET}.sha256" "$TMP/${ASSET}.sha256"; then
  FILE_SUM=$(awk 'NF { print $1; exit }' "$TMP/${ASSET}.sha256" | tr 'A-F' 'a-f')
fi
case "$DIGEST" in
  sha256:*) API_SUM=$(printf '%s' "${DIGEST#sha256:}" | tr 'A-F' 'a-f') ;;
esac
if [[ -n "$FILE_SUM" && -n "$API_SUM" && "$FILE_SUM" != "$API_SUM" ]]; then
  die "The published checksum and the GitHub digest for ${ASSET} disagree."
fi
EXPECTED="${FILE_SUM:-$API_SUM}"
# A variable, not a literal: bash 3.2 on macOS mishandles {n} inside [[ =~ ]].
sha_re='^[0-9a-f]{64}$'
[[ "$EXPECTED" =~ $sha_re ]] || die "No sha256 checksum for ${ASSET}."
ACTUAL=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}' | tr 'A-F' 'a-f')
[[ "$ACTUAL" == "$EXPECTED" ]] || die "Checksum mismatch for ${ASSET}."
echo "Checksum matches."

STAGE="$TMP/unpacked"
mkdir -p "$STAGE"
if [[ "$ASSET" == "Refill.zip" ]]; then
  ditto -x -k "$ARCHIVE" "$STAGE"
else
  command -v hdiutil >/dev/null 2>&1 || die "hdiutil is required to open the disk image."
  MOUNT="$TMP/mnt"
  mkdir -p "$MOUNT"
  hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT" "$ARCHIVE" >/dev/null
  [[ -d "$MOUNT/Refill.app" && ! -L "$MOUNT/Refill.app" ]] || die "The disk image does not contain Refill.app."
  ditto "$MOUNT/Refill.app" "$STAGE/Refill.app"
  hdiutil detach "$MOUNT" -quiet >/dev/null
  MOUNT=""
fi

SRC="$STAGE/Refill.app"
[[ -d "$SRC" && ! -L "$SRC" ]] || die "The archive does not contain Refill.app."
[[ -f "$SRC/Contents/MacOS/Refill" && ! -L "$SRC/Contents/MacOS/Refill" ]] || die "Refill.app has no executable."
GOT=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SRC/Contents/Info.plist" 2>/dev/null || true)
[[ "$GOT" == "$BUNDLE_ID" ]] || die "This archive is not Refill (bundle id: ${GOT:-unknown})."

if [[ -L "$DEST" ]]; then
  die "/Applications/Refill.app is a symlink. Refusing to follow it."
fi

if pgrep -x Refill >/dev/null 2>&1; then
  echo "Quitting Refill so it can be replaced."
  osascript -e 'tell application "Refill" to quit' >/dev/null 2>&1 || true
  i=0
  while pgrep -x Refill >/dev/null 2>&1; do
    i=$((i + 1))
    [[ "$i" -ge 20 ]] && break
    sleep 0.25
  done
fi

xattr -dr com.apple.quarantine "$SRC" 2>/dev/null || true

if [[ -w /Applications ]]; then
  rm -rf "$DEST"
  ditto "$SRC" "$DEST"
  xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
  if xattr -lr "$DEST" 2>/dev/null | grep -q 'com.apple.quarantine'; then
    die "Could not clear the quarantine flag. Open Refill, then go to System Settings → Privacy & Security → Open Anyway."
  fi
else
  echo "/Applications is not writable. An administrator password is needed to install Refill there."
  sudo rm -rf "$DEST"
  sudo ditto "$SRC" "$DEST"
  sudo xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
  if sudo xattr -lr "$DEST" 2>/dev/null | grep -q 'com.apple.quarantine'; then
    die "Could not clear the quarantine flag. Open Refill, then go to System Settings → Privacy & Security → Open Anyway."
  fi
fi

open "$DEST"
echo "Refill ${TAG} is in /Applications and opening."
