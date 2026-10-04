#!/bin/bash
# Print a Homebrew cask for Refill, in the style of
# https://github.com/StepanBlaha/homebrew-tap/blob/main/Casks/brink.rb
#
# The tap is a separate repo. Paste the output into Casks/refill.rb there.
#
#   scripts/homebrew-cask.sh build/Refill.dmg
#   scripts/homebrew-cask.sh --template          # version from VERSION, sha left blank
#
# Version: REFILL_VERSION, or the first argument if it looks like 1.2.3, or VERSION.
set -euo pipefail
cd "$(dirname "$0")/.."

version_from_file() { tr -d '[:space:]' < VERSION; }

sha_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

V="${REFILL_VERSION:-}"
DMG=""
TEMPLATE=0

for arg in "$@"; do
  case "$arg" in
    --template) TEMPLATE=1 ;;
    *.dmg) DMG="$arg" ;;
    *)
      if [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        V="$arg"
      else
        echo "usage: scripts/homebrew-cask.sh [--template] [version] [Refill.dmg]" >&2
        exit 1
      fi
      ;;
  esac
done

[[ -n "$V" ]] || V=$(version_from_file)

if [[ "$TEMPLATE" -eq 1 ]]; then
  SHA="REPLACE_WITH_SHA256"
elif [[ -n "$DMG" ]]; then
  [[ -f "$DMG" ]] || { echo "No such file: $DMG" >&2; exit 1; }
  SHA=$(sha_of "$DMG")
else
  for candidate in "build/Refill.dmg" "build/Refill-${V}.dmg"; do
    if [[ -f "$candidate" ]]; then
      DMG="$candidate"
      break
    fi
  done
  if [[ -z "$DMG" ]]; then
    echo "No dmg found. Build one with scripts/package.sh, or pass a path. Use --template to print a blank sha256." >&2
    exit 1
  fi
  SHA=$(sha_of "$DMG")
fi

cat <<EOF
cask "refill" do
  version "${V}"
  sha256 "${SHA}"

  url "https://github.com/StepanBlaha/Refill/releases/download/v#{version}/Refill.dmg"
  name "Refill"
  desc "Menu bar app that watches your AI subscription limits"
  homepage "https://stepanblaha.github.io/Refill/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "Refill.app"

  zap trash: [
    "~/.config/refill",
    "~/Library/Preferences/cz.stepanblaha.refill.plist",
    "~/Library/Group Containers/FW5CYB98R7.cz.stepanblaha.refill",
  ]

  caveats <<~EOS
    Refill is not notarized yet. The first time, open Refill, then go to
    System Settings → Privacy & Security → Open Anyway. Or run:
      xattr -dr com.apple.quarantine /Applications/Refill.app
  EOS
end
EOF
