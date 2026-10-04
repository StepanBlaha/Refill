#!/bin/bash
# Print GitHub release notes for a version.
# Usage: scripts/release-notes.sh [version]
# The New / Improved / Fixed sections are copied from that version in CHANGELOG.md.
# The workflow publishes this text instead of GitHub's generated changelog.
set -euo pipefail
cd "$(dirname "$0")/.."
V="${1:-$(tr -d '[:space:]' < VERSION)}"

section=$(awk -v ver="$V" '
  BEGIN { hdr = "## [" ver "]" }
  substr($0, 1, length(hdr)) == hdr { on = 1; next }
  on && substr($0, 1, 3) == "## " { exit }
  on { print }
' CHANGELOG.md)

if ! printf '%s\n' "$section" | grep -q '[^[:space:]]'; then
  echo "No CHANGELOG.md section for ${V}. Add ## [${V}] with ### New, ### Improved and/or ### Fixed." >&2
  exit 1
fi

extract() {
  printf '%s\n' "$section" | awk -v name="$1" '
    $0 == "### " name { on = 1; next }
    on && substr($0, 1, 4) == "### " { exit }
    on { print }
  '
}

has_body() {
  printf '%s\n' "$1" | grep -q '[^[:space:]]'
}

notes=""
for name in New Improved Fixed Security; do
  body=$(extract "$name" | sed '/./,$!d')
  if has_body "$body"; then
    notes="${notes}
### ${name}

${body}
"
  fi
done

if ! has_body "$notes"; then
  echo "CHANGELOG.md section ${V} has no ### New, ### Improved or ### Fixed entries." >&2
  exit 1
fi

cat <<EOF
**Refill is free and open source (MIT).** macOS 14 Sonoma or later. It isn't notarized yet.

### Install or update

- **Homebrew:** \`brew install --cask stepanblaha/tap/refill\`
- **One line:** \`curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/install.sh | bash\`
- **By hand:** download **Refill.zip** below (or **Refill.dmg**), and move **Refill** to Applications, replacing the old version. Settings in \`~/.config/refill\` are kept. Then open Refill and go to **System Settings → Privacy & Security → Open Anyway**, or run \`xattr -dr com.apple.quarantine /Applications/Refill.app\`.

Homebrew and the one-line installer clear the quarantine flag. The zip is an ad-hoc signed app (\`codesign --sign -\`). Checksums are **Refill.zip.sha256** and **Refill.dmg.sha256**.

Refill is an independent app and is not affiliated with, endorsed by, or sponsored by Anthropic, OpenAI, GitHub, Cursor or Google.

---
${notes}
EOF
