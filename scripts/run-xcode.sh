#!/bin/bash
# xcodegen -> xcodebuild (signed, app + widgets) -> /Applications/Refill.app -> relaunch.
# Usage: scripts/run-xcode.sh [--build-only] [Debug|Release]
set -euo pipefail
BUILD_ONLY=0
if [ "${1:-}" = "--build-only" ]; then BUILD_ONLY=1; shift; fi
CONFIG="${1:-Debug}"
cd "$(dirname "$0")/.."

xcodegen generate --quiet
mkdir -p build
LOG="build/xcodebuild.log"
if ! xcodebuild -project Refill.xcodeproj -scheme Refill -configuration "$CONFIG" \
    -derivedDataPath build/xcode -allowProvisioningUpdates build > "$LOG" 2>&1; then
  grep -E "error:" "$LOG" | sort -u >&2 || tail -30 "$LOG" >&2
  echo "xcodebuild failed (full log: $LOG)" >&2
  exit 1
fi
PRODUCT="build/xcode/Build/Products/$CONFIG/Refill.app"
[ -d "$PRODUCT" ] || { echo "Build failed: $PRODUCT missing" >&2; exit 1; }
if [ "$BUILD_ONLY" = 1 ]; then
  rm -rf build/Refill.app; ditto "$PRODUCT" build/Refill.app
  echo "Built build/Refill.app"; exit 0
fi
pkill -x Refill || true
sleep 1
rm -rf /Applications/Refill.app
ditto "$PRODUCT" /Applications/Refill.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Refill.app || true
open /Applications/Refill.app
echo "Installed and launched /Applications/Refill.app"
