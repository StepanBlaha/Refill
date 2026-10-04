# Agent context

Handoff for the notch-banner fix. No release was cut and no tag was pushed.

PR #2 (`cursor/release-readiness-2c9d`) also adds this file, with the release-kit notes. It does not touch Swift sources. If that PR merges first, keep both writeups in this file.

## What was wrong

On a notched MacBook the open Drip banner was a fixed pill (404×86, and taller once the overflow fix let the message grow it) centered on the top of the screen. The camera housing sits in that same top-centre band, so the icon and the text landed behind it. Collapsed, the silhouette already read `safeAreaInsets` and the auxiliary areas. Open, it ignored them.

## What landed

- `Sources/Refill/Notch/NotchLayout.swift`. Pure layout. The housing rect is `safeAreaInsets.top` tall and the gap between `auxiliaryTopLeftArea` and `auxiliaryTopRightArea` wide. Nothing is hardcoded to 185×32 or 220×38.
- Notched display, lobes wide enough: the pill is exactly the housing height. Drip sits in the left lobe, one truncated line in the right, 8pt clear of the camera. The black shape bridges the housing the way NotchNook does, so the wings read as one island. Symmetric lobes keep the shape centered on the camera while it grows.
- Lobes too narrow, housing shorter than a text row, or a non-zero top inset with no auxiliary areas: the whole pill, content included, drops strictly below the obscured band. Still one compact row.
- No notch (external display, Mac mini, Studio Display): a compact pill at the top centre, about the menu-bar tall (24–36pt) and 214pt wide. A bottom Dock does not stretch it.
- The screen is chosen when the alert opens: the display under the pointer, otherwise the main display. `NSApplication.didChangeScreenParametersNotification` lays it out again (resolution, connect, disconnect, arrangement).
- Text truncates (`lineLimit(1)`). The pill does not measure the string and grow. Dynamic Type scales the font only up to what the band can hold.
- `Tests/RefillTests/NotchLayoutTests.swift` covers the measured 16-inch geometry, a 14-inch-class geometry, a shifted display, plain and external panels, a Dock, narrow lobes, a short housing, a bare top inset, and pointer vs main-display selection.
- `Refill --render <dir>` also writes `notch-notched.png`, `notch-plain.png`, and `notch-below.png`. The notched shot strokes the housing; the below shot dashes the obscured band.

## What this environment could not do

This machine is Linux. There is no Swift toolchain and no Mac display, so `swift test` was not run and `Refill --render` was not run. The 16-inch numbers in the tests are a published `NSScreen` dump (16-inch M4 Pro, More Space, September 2026: inset 38, lobes 918, housing 220×38), not a reading from Štěpán's MacBook. The 14-inch sample is the same shape of geometry (1512×982, inset 32, housing 184) and is not a measurement of his panel.

## What to check on the notched Mac

```bash
swift test
# build the app the usual way, then:
# Settings → General → Preview notch
Refill --render /tmp/refill-shots
```

On the built-in panel the open pill should be about as tall as the menu bar. Drip is left of the camera, the message is right of it and ends in an ellipsis if it is long. Nothing readable should sit behind the housing. Move the pointer to an external display and preview again: a small pill at that panel's top centre. Change the resolution, or unplug a display, while it is on screen: it should move to the display that is still there.
