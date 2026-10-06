#!/bin/bash
# Print a Homebrew cask for Refill, in the style of
# https://github.com/StepanBlaha/homebrew-tap/blob/main/Casks/brink.rb
#
# The tap is a separate repo. Paste the output into Casks/refill.rb there.
# Brink's cask has caveats only. This one also clears the quarantine flag in
# postflight_steps, so an unsigned app is not stuck on Gatekeeper.
# `postflight do` is deprecated; Homebrew wants `postflight_steps` and `{{appdir}}`.
#
#   scripts/homebrew-cask.sh build/Refill.zip
#   scripts/homebrew-cask.sh build/Refill.dmg   # 0.1.1 shipped a disk image only
#   scripts/homebrew-cask.sh --template          # version from VERSION, sha left blank
#
# Version: REFILL_VERSION, or the first argument if it looks like 1.2.3, or VERSION.
# The url uses the stable asset name (Refill.zip or Refill.dmg), which is what
# the release workflow uploads.
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
FILE=""
TEMPLATE=0
ASSET="Refill.zip"

for arg in "$@"; do
  case "$arg" in
    --template) TEMPLATE=1 ;;
    *.dmg) FILE="$arg"; ASSET="Refill.dmg" ;;
    *.zip) FILE="$arg"; ASSET="Refill.zip" ;;
    *)
      if [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        V="$arg"
      else
        echo "usage: scripts/homebrew-cask.sh [--template] [version] [Refill.zip|Refill.dmg]" >&2
        exit 1
      fi
      ;;
  esac
done

[[ -n "$V" ]] || V=$(version_from_file)

if [[ "$TEMPLATE" -eq 1 ]]; then
  SHA="REPLACE_WITH_SHA256"
elif [[ -n "$FILE" ]]; then
  [[ -f "$FILE" ]] || { echo "No such file: $FILE" >&2; exit 1; }
  SHA=$(sha_of "$FILE")
else
  for candidate in "build/Refill.zip" "build/Refill-${V}.zip" "build/Refill.dmg" "build/Refill-${V}.dmg"; do
    if [[ -f "$candidate" ]]; then
      FILE="$candidate"
      case "$candidate" in
        *.zip) ASSET="Refill.zip" ;;
        *.dmg) ASSET="Refill.dmg" ;;
      esac
      break
    fi
  done
  if [[ -z "$FILE" ]]; then
    echo "No zip or dmg found. Build one with scripts/package.sh, or pass a path. Use --template to print a blank sha256." >&2
    exit 1
  fi
  SHA=$(sha_of "$FILE")
fi

cat <<EOF
cask "refill" do
  version "${V}"
  sha256 "${SHA}"

  url "https://github.com/StepanBlaha/Refill/releases/download/v#{version}/${ASSET}"
  name "Refill"
  desc "Menu bar app that watches your AI subscription limits"
  homepage "https://stepanblaha.github.io/Refill/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "Refill.app"

  postflight_steps do
    on_macos do
      run "/usr/bin/xattr",
          args: ["-dr", "com.apple.quarantine", "{{appdir}}/Refill.app"],
          must_succeed: false
    end
  end

  zap trash: [
    "~/.config/refill",
    "~/Library/Preferences/cz.stepanblaha.refill.plist",
    "~/Library/Group Containers/FW5CYB98R7.cz.stepanblaha.refill",
  ]

  caveats <<~EOS
    Refill is not notarized yet. The cask clears the quarantine flag.
    If the first open is still blocked, go to
    System Settings → Privacy & Security → Open Anyway. Or run:
      xattr -dr com.apple.quarantine /Applications/Refill.app
  EOS
end
EOF
