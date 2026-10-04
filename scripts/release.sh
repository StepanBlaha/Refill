#!/bin/zsh
# Cut a release: scripts/release.sh 0.2.0
# Bumps VERSION + project.yml, commits, tags v<version>, pushes. GitHub Actions builds
# the .dmg and publishes the Release; the site's Download button picks it up automatically.
set -euo pipefail
cd "$(dirname "$0")/.."
V="${1:?usage: scripts/release.sh <version>}"
[[ -z "$(git status --porcelain)" ]] || { echo "Commit or stash your changes first." >&2; exit 1; }
swift test > /dev/null
# Notes come from CHANGELOG.md (### New / Improved / Fixed). Fail before tagging if they're missing.
scripts/release-notes.sh "$V" > /tmp/refill-notes.md
if grep -qx "## [$V] - Unreleased" CHANGELOG.md; then
  sed -i '' "s/^## \[$V\] - Unreleased$/## [$V] - $(date +%Y-%m-%d)/" CHANGELOG.md
fi
echo "$V" > VERSION
sed -i '' "s/MARKETING_VERSION: .*/MARKETING_VERSION: $V/" project.yml
git commit -qam "Release $V"
git tag "v$V"
git push -q origin HEAD "v$V"
echo "Pushed v$V. Watch it build: https://github.com/StepanBlaha/Refill/actions"
echo "Release notes that will be published:"
cat /tmp/refill-notes.md
echo "After the dmg is built, the job log prints the Homebrew cask. Or locally: scripts/homebrew-cask.sh build/Refill.dmg"
