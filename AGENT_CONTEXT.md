# Agent context

## Marketing assets

Handoff for the Brink-style marketing set. No release was cut and no tag was pushed. No Swift sources were edited.

## What landed

- `marketing/APPSTORE.md`. Store copy in the same shape as Brink's: name, subtitle, promotional text, description, keywords, what's new for 0.1.1, categories, age rating, privacy ("Data Not Collected"), URLs, review notes, and a 2880×1800 shot list. Counts are in the file. It does not claim the app is on the store. The public build is still the GitHub dmg, and it is not notarized.
- `marketing/social/`. Seven carousel slides (1080×1350), six stories (1080×1920, 250 px kept clear at the top and bottom), `x-card.png` (1600×900), `hero-still.png` (1600×1000), `reel-cover.png`, `reel.mp4` (1080×1920, about 13 s, no audio), `refill-square-1080.mp4` (1080×1080, about 10 s, no audio). `README.md` lists each file. Copy does not invent a user count or a testimonial. The non-affiliation line is on the CTA slides, the X card, and story 3 (that frame names Claude and Codex).
- `marketing/screenshots/`. Numbered desktop shots `01`–`06` (2880×1800, captions), plus the five names `Refill --render` writes: `menu.png`, `moods.png`, `settings.png`, `history.png`, `accounts.png`.
- `marketing/media/`. `menu-bar.gif`, `notch-reset.gif`, `notch-warning.gif`, `history.gif`, `install.gif`. Each is under 8 seconds.
- `site/public/media/hero.mp4` and `hero-poster.jpg`. The press page links them and plays the video with controls. The home page is unchanged. `npm run build` in `site/` is the check.
- `scripts/marketing/stage.html` draws Drip, the menu and the notch from `Mascot.swift`, `RefillApp.swift` (`MenuView`) and `Notch/NotchView.swift` + `NotchShape.swift`. `scripts/marketing/render.mjs` screenshots it with Playwright (system Chrome). `scripts/marketing/video.sh` builds the GIFs and MP4s with ffmpeg. `scripts/capture-marketing.sh` is the Mac path: it runs `Refill --render` and `--render-og`, and prints the notch, GIF and numbered-shot recordings the binary cannot make.

The history chart in the stand-ins is a drawing. The ~8%/h, 71% peak and "1" reset are not a measurement. Sample emails are the `@example.cz` addresses already in `PreviewRender`.

## What this environment could not do

This machine is Linux. There is no Swift toolchain and no Mac display, so `swift test` was not run and `Refill --render` was not run. The pictures are HTML, not screen recordings. Replace the five `--render` stills, the GIFs and the numbered shots on a Mac with `scripts/capture-marketing.sh`. The social folder is composed type and stays unless you rebuild it with `node scripts/marketing/render.mjs`.

## Notch banner

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

## Release kit

Handoff for the release-readiness pass that lines Refill up with the public Brink repo. No app behaviour was changed. No release was cut and no tag was pushed.

## What landed

- `CHANGELOG.md` in Keep a Changelog form. `0.1.0` (2026-09-30, tag `v0.1.0`) is summarized from git history. `0.1.1` is still `Unreleased` and covers the finished landing page, the top-notch overflow fix, and the public README. `scripts/release.sh` rewrites that heading to the date when you cut the release.
- `CONTRIBUTING.md`, `SECURITY.md`, `TRADEMARKS.md`. The name Refill, the Drip mascot and the app icon are excluded from the MIT license, matching `legal/NOTICE.md`. "Refill" is still a provisional name. A trademark search has not been done.
- `.github/ISSUE_TEMPLATE/` (`bug_report.yml`, `feature_request.yml`, `config.yml`) and `.github/pull_request_template.md`.
- `branding/BRAND.md` (colours from `Theme.swift` / the site, Drip's moods, name usage). `branding/AppIcon.icns` and `branding/AppIcon.iconset/` are generated from `branding/icon-1024.png` by `branding/make_icns.py` (Pillow). The built app still takes its icon from `Resources/Assets.xcassets`, which is how Brink is wired. The icns is the press-kit file, not a second app icon.
- Release notes. `scripts/release-notes.sh` prints Brink's shape: free and MIT, macOS 14+, install/update, the not-notarized first launch (Open Anyway, or `xattr`), the non-affiliation line, then **New / Improved / Fixed** copied from that version in `CHANGELOG.md`. `.github/workflows/release.yml` publishes that text (`body_path`) and uploads **only** `build/Refill.dmg`. The old second asset was a byte-for-byte copy, which broke nothing except the duplicate. `releases/latest/download/Refill.dmg` still works. A versioned URL is `releases/download/vX.Y.Z/Refill.dmg`.
- `scripts/homebrew-cask.sh` prints a cask in the style of `Casks/brink.rb`. The release job prints it after the dmg exists. The tap is a different repo, so the cask is not committed here.
- `marketing/LAUNCH.md`, `LISTINGS.md`, `PLAYBOOK.md`, `PERSONAL-POSTS.md`, and `marketing/media/README.md`. Product Hunt, Show HN, r/macapps, r/ClaudeAI. GIFs were not generated.
- Site: `/press/` and `/acknowledgements/` (same notices as `/notice/`, which stays). Footer links, `site/public/sitemap.xml` and `site/public/llms.txt` include both. `robots.txt` already points at that sitemap, so it was left as-is. The notice page also gained the name-and-icon bullet that was in `legal/NOTICE.md` and missing on the site.
- `npm run build` in `site/` succeeds (static export, pages `/`, `/press`, `/acknowledgements`, `/notice`, `/privacy`, `/terms`).

## What this environment could not do

- **GitHub About box.** `PATCH /repos/StepanBlaha/Refill` and `PUT .../topics` returned `403 Resource not accessible by integration`. Values to paste are below.
- **Demo GIFs.** `Refill --render` is a Mac binary and writes still PNGs (menu, moods, settings, history, accounts). It does not draw the notch. What to record is in `marketing/media/README.md`.
- **`swift test`.** This machine has no Swift toolchain, and `Package.swift` is macOS 14. No Swift sources were edited.
- **The Homebrew tap.** https://github.com/StepanBlaha/homebrew-tap is separate. Don't add the cask until 0.1.1's dmg exists, or the sha256 will be wrong.

## What Štěpán does next

1. Merge this PR.
2. Cut **0.1.1** from a clean `main` (this stamps the changelog date, bumps `VERSION` and `project.yml`, tags `v0.1.1`, and lets Actions build one dmg and publish the notes):

   ```bash
   scripts/release.sh 0.1.1
   ```

3. Add the cask to https://github.com/StepanBlaha/homebrew-tap as `Casks/refill.rb`. Copy it from the release job log, or:

   ```bash
   gh release download v0.1.1 --pattern Refill.dmg --dir /tmp
   REFILL_VERSION=0.1.1 scripts/homebrew-cask.sh /tmp/Refill.dmg
   ```

   Install line after that push: `brew install --cask stepanblaha/tap/refill`.

4. Set the repo About box (gear on the repo home):

   - **Description:** `Menu bar app for macOS that watches your AI subscription limits and signals the moment one resets. Native Swift, free.`
   - **Website:** `https://stepanblaha.github.io/Refill/`
   - **Topics:** `macos` `macos-app` `menu-bar` `notch` `swift` `swiftui` `claude` `codex` `ai` `usage-tracker`

   ```bash
   gh api -X PATCH repos/StepanBlaha/Refill \
     -f description='Menu bar app for macOS that watches your AI subscription limits and signals the moment one resets. Native Swift, free.' \
     -f homepage='https://stepanblaha.github.io/Refill/'
   gh api --method PUT -H "Accept: application/vnd.github+json" \
     repos/StepanBlaha/Refill/topics --input - <<'EOF'
   {"names":["macos","macos-app","menu-bar","notch","swift","swiftui","claude","codex","ai","usage-tracker"]}
   EOF
   ```

## Cask to paste after 0.1.1 (sha256 filled by the script)

```ruby
cask "refill" do
  version "0.1.1"
  sha256 "REPLACE_WITH_SHA256"

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
```
