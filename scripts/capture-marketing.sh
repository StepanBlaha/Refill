#!/bin/bash
# Replace the HTML stand-ins with captures from the real Refill app.
# Needs macOS. The pictures already in the repo were drawn in Chrome
# (scripts/marketing/render.mjs) because this project is also built on Linux.
#
#   scripts/capture-marketing.sh
#
# What it does on a Mac:
#   1. Runs `Refill --render` into marketing/screenshots (menu, moods, settings, history, accounts).
#   2. Runs `Refill --render-og` for branding/og-1200x630.png.
#   3. Prints the recordings --render cannot make: the notch, the GIFs, the numbered desktop shots.
#
# It does not delete marketing/social or the numbered screenshots. Those stay until you
# replace them. Sample data only: no real token, webhook, or full personal email.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(uname -s)" != "Darwin" ]; then
  cat <<'EOF'
This script runs the Refill app and needs macOS.

The PNGs, GIFs and MP4s already in marketing/ and site/public/media/ are HTML
stand-ins (Drip, the menu, and the notch pill drawn from the Swift views).
Regenerate those on any machine with Chrome:

  npm install --prefix scripts/marketing playwright-core
  node scripts/marketing/render.mjs

On your Mac, run this script again. It overwrites the five --render stills
and tells you which clips to record by hand.
EOF
  exit 1
fi

BIN=""
if [ -x .build/debug/Refill ]; then
  BIN=".build/debug/Refill"
elif [ -x build/Refill.app/Contents/MacOS/Refill ]; then
  BIN="build/Refill.app/Contents/MacOS/Refill"
elif [ -x /Applications/Refill.app/Contents/MacOS/Refill ]; then
  BIN="/Applications/Refill.app/Contents/MacOS/Refill"
else
  echo "No Refill binary. Build one first:" >&2
  echo "  swift build" >&2
  echo "  # or: scripts/run-xcode.sh --build-only" >&2
  exit 1
fi

mkdir -p marketing/screenshots marketing/media
echo "Using $BIN"
"$BIN" --render marketing/screenshots
"$BIN" --render-og branding/og-1200x630.png
cp -f branding/og-1200x630.png site/public/og.png

cat <<'EOF'

--render wrote these (sample accounts, fake @example.cz addresses):
  marketing/screenshots/menu.png
  marketing/screenshots/moods.png
  marketing/screenshots/settings.png
  marketing/screenshots/history.png
  marketing/screenshots/accounts.png
  branding/og-1200x630.png  (also copied to site/public/og.png)

--render does not draw the notch, and it does not animate. These files are still
the HTML stand-ins. Replace them with a screen recording when you can.

Record on a Mac with sample or demo accounts. Do not record a real token, a
webhook URL, or a full personal email. Keep each GIF under about 8 seconds.

  marketing/media/menu-bar.gif       Menu opening. A tank draining, Drip changing face, then a refill.
  marketing/media/notch-reset.gif    Settings → General → Preview notch. A short line and a long one,
                                     so the pill is visibly tall enough and nothing sits under the camera.
  marketing/media/notch-warning.gif  A warning (amber) and an empty tank (red).
  marketing/media/history.gif        History opening, with the burn-rate chart. A fresh install shows
                                     "Collecting data" until Refill has sampled for about an hour.
  marketing/media/install.gif        Opening Refill.dmg and dragging Refill to Applications.

Numbered desktop shots (captions, wallpaper), same idea as Brink's shot list.
--render does not produce these. Record them, or keep the HTML versions.

  marketing/screenshots/01-menu-bar.png     Menu open. Caption: Your AI tanks, watched.
  marketing/screenshots/02-notch-reset.png  Notch, "Tank's full". Caption: The moment it refills.
  marketing/screenshots/03-history.png      History chart. Caption: Will this pace hit empty?
  marketing/screenshots/04-settings.png     Settings → General. Caption: Signals, the way you want them.
  marketing/screenshots/05-accounts.png     Settings → Accounts. Caption: The logins already on your Mac.
  marketing/screenshots/06-moods.png        Drip's five moods. Caption: Drip keeps watch.

Social stills and the two MP4s are composed pages, not app captures. Rebuild them
with scripts/marketing/render.mjs after you drop real screenshots in, if you wire
the stage to those files. Until then, marketing/social/ is the HTML set.

The notch clip is the one launch posts should lead with.
EOF
