# Agent context

## Multi-account and sleep-time ntfy (0.3.0)

Handoff for the 0.3.0 work on branch `cursor/multi-account-sleep-push-7df0`. No tag was created and no GitHub release was published. The Homebrew tap was not touched. This agent cannot push to `StepanBlaha/homebrew-tap`.

## What landed

- Codex: `CodexProvider.discover` always keeps `~/.codex` as `codex:default`. `CODEX_HOME`, `~/.codex-*`, `~/.codex_*` and `extraCodexDirs` are `codex:<absolute path>`. Empty auto-discovered homes are skipped. **Add** writes the new folder into `extraCodexDirs` and opens Terminal with `CODEX_HOME` set (`codex login`, then `codex`). `scripts/add-codex-account.sh` does the same without the defaults write.
- Copilot: every `github.com` login from `gh auth status`. `copilotAnchorLogin` keeps `copilot:default` stable. Other ids are `copilot:<login>` (`copilot:login:default` if the login is the word `default`). No gh logins: the old editor token path, one account. Enterprise hosts ignored. Fetch is concurrent and skips hidden ids.
- Gemini: `~/.gemini` stays `gemini:default`. `GEMINI_CLI_HOME` is a home directory; creds are `$GEMINI_CLI_HOME/.gemini/oauth_creds.json`. Also `~/.gemini-*`, `~/.gemini-accounts/<name>` (prefer nested) and `extraGeminiDirs`. A folder that already contains `oauth_creds.json` is used as-is. Add opens Terminal with `GEMINI_CLI_HOME=~/.gemini-accounts/<name>`. `scripts/add-gemini-account.sh` matches.
- Cursor: still `cursor:default`. One `cursorAuth` token in `state.vscdb` per Mac user. Documented, not split.
- Names: UserDefaults `accountLabels`. `AccountSnapshot.label`, computed `title` (label, else email, else name) and `detail`. Menu, notch (via `RefillEvent.accountName`), dashboard, widgets, history samples, companion and the scheduled ntfy body use `title`. **⋯ → Rename…**. Blank clears it.
- Hide already existed (`hiddenAccounts`). Codex, Copilot, Gemini and Cursor now skip hidden ids before reading. Trash covers extra Codex and Gemini dirs as well as Claude. No separate mute.
- ntfy: `NtfyScheduler` posts `{server}/{topic}/{messageId}` with `At`, `Title: Refilled`, tags `zap`, priority 4. `messageId` is `refill-` + first 16 hex of SHA-256(`accountId|windowKey`), same shape as the external script, so a republish replaces. Bookings in `~/.config/refill/ntfy-schedule.json` mode 0600, no token. Awake at reset: cancel the pending message and send the normal ntfy push. Asleep through delivery: skip the second ntfy send. A booking due within 45s is not deleted by a sync. Quiet hours plus "mute phone and chat" skips scheduling when the delivery hour is quiet. `Integrations.save` posts `.refillIntegrationsChanged` so a new ntfy sink schedules without waiting for the next poll.
- Docs: README, `docs/GUIDES.md`, `docs/SETUP.md`, the site guide data, `legal/PRIVACY.md` and the site privacy page. CHANGELOG `## [0.3.0] - Unreleased`. `VERSION` and `project.yml` `MARKETING_VERSION` are `0.3.0`.
- `.github/workflows/ci.yml` runs `swift test` on `macos-15` for pull requests and pushes to `main`. `release.yml` still only runs on tags `v*` and workflow_dispatch. It does not run on a pull request.

## What this environment could not do

This machine is Linux. There is no Swift toolchain and no Mac, so `swift test` was not run here and the app was not launched. `bash scripts/release-notes.sh 0.3.0` was run to confirm the changelog section parses. UI hover, press and focus states were not exercised in a browser: this is a native Mac app. The macOS CI workflow on the pull request is the build check.

## What Štěpán does next

1. Read the CI result on the pull request (`swift test` on macos-15). Merge when it is green. Do not tag from the pull request.
2. On a Mac, from a clean `main` after the merge:

   ```bash
   scripts/release.sh 0.3.0
   ```

   That runs `swift test`, requires the changelog section, rewrites `## [0.3.0] - Unreleased` to today's date, writes `VERSION` and `MARKETING_VERSION`, commits `Release 0.3.0`, tags `v0.3.0`, and pushes the branch and the tag. GitHub Actions (`.github/workflows/release.yml`, macos-15) then builds, runs tests again, and uploads `Refill.dmg`, `Refill.zip`, and a `.sha256` for each. The job log prints a Homebrew cask for the zip.
3. Paste that cask into `StepanBlaha/homebrew-tap` `Casks/refill.rb` and merge it yourself. The url should be `Refill.zip`. Keep the quarantine `postflight`. This agent cannot push the tap.
4. On the Mac that should run it:

   ```bash
   brew upgrade --cask refill
   ```

   First install is `brew install --cask stepanblaha/tap/refill`.
5. If `~/Library/LaunchAgents/local.refill.ntfy-schedule.plist` is loaded, boot it out. Refill schedules the ntfy pushes itself. The commands are in `docs/SETUP.md`.

The sections below are earlier handoffs. Where they disagree with this one, this one is current. In particular: do not cut 0.2.1 again, and do not treat the external ntfy script as the way resets are scheduled.

## Unsigned installs

Handoff for installing Refill without notarization. No release was cut and no tag was pushed.

The owner has no Apple Developer license. Gatekeeper blocks a downloaded app until quarantine is cleared. Brink is installable with `brew install --cask stepanblaha/tap/brink` from https://github.com/StepanBlaha/homebrew-tap (`Casks/brink.rb`). Brink's cask has caveats and no `postflight`.

## What landed

- `scripts/package.sh` writes `build/Refill.dmg` and `build/Refill.zip`, then a `.sha256` for each (`shasum -a 256`: hash, two spaces, filename). The zip is `ditto -c -k --keepParent` of `Refill.app`, so the app is the top item and the signature survives. If `DEVELOPER_ID` is unset and `codesign --verify` fails, the app is ad-hoc signed with `codesign --force --deep --sign -`. `--deep` covers the widget extension. Checksums are written after an optional staple, so a notarized dmg's hash matches the uploaded file.
- `.github/workflows/release.yml` uploads `Refill.dmg`, `Refill.zip`, and both `.sha256` files. It does not upload a second copy under a versioned name. The job log prints a Homebrew cask for the zip.
- `scripts/install.sh` is the one-line installer (`curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/install.sh | bash`). It reads the latest GitHub release, prefers `Refill.zip`, checks sha256 (the `.sha256` asset, and the release asset's `digest` when that file is present too; they must agree), refuses a bundle id other than `cz.stepanblaha.refill`, replaces `/Applications/Refill.app`, runs `xattr -dr com.apple.quarantine`, and opens the app. `sudo` is used only when `/Applications` is not writable. Download URLs are built from the tag, not taken from the JSON. 0.1.1 has no zip, so the script installs that release's disk image and checks the digest GitHub already publishes (`sha256:71ea976a6003d86dbaae31e67ee1f3a8e55e257391c358f2e15f7ff2d6b5f2fd`).
- `scripts/release.sh` stamps the changelog date with `grep -Fxq`. The old pattern treated `[0.1.1]` as a character class, which is why 0.1.1 stayed "Unreleased". The heading is now `## [0.1.1] - 2026-10-04`.
- README, the landing-page Download section, `CHANGELOG.md` (Unreleased), `scripts/release-notes.sh`, and `site/public/llms.txt` list three options: `brew install --cask stepanblaha/tap/refill`, the curl installer, and a manual zip or disk image plus **System Settings → Privacy & Security → Open Anyway**.
- The 0.1.1 changelog line that said the notch banner grows to fit was removed. That behavior was reverted in PR #3 (`b171b88`, "Restore the original notch pill") before the tag. The published GitHub release body for v0.1.1 still has the sentence. This branch does not edit that release.
- `scripts/homebrew-cask.sh` prints a cask for a zip or a dmg, with a `postflight` that clears quarantine.

## Homebrew tap

The cask was prepared and committed locally, then `git push` to https://github.com/StepanBlaha/homebrew-tap was rejected: `Permission to StepanBlaha/homebrew-tap.git denied to cursor[bot]`. This agent's token can push to Refill and cannot push to the tap, so the tap pull request was not opened. Paste `Casks/refill.rb` below (or run `REFILL_VERSION=0.1.1 scripts/homebrew-cask.sh` on the downloaded dmg) and open the PR from an account that can push to the tap.

The file is modelled on `Casks/brink.rb`. Brink's cask has caveats and no `postflight`. This one adds a `postflight` that clears quarantine, because otherwise `brew install` still trips Gatekeeper.

- version `0.1.1`
- url is `Refill.dmg`, because 0.1.1 has no zip
- sha256 `71ea976a6003d86dbaae31e67ee1f3a8e55e257391c358f2e15f7ff2d6b5f2fd`, from downloading `https://github.com/StepanBlaha/Refill/releases/download/v0.1.1/Refill.dmg` and running `shasum -a 256`. It matches the asset `digest` on the GitHub API.
- `postflight` runs `/usr/bin/xattr -dr com.apple.quarantine` on `#{appdir}/Refill.app` (`must_succeed: false`, so a missing attribute does not fail the install)
- caveats still mention Open Anyway

On the next Refill release, point that url at `Refill.zip` and replace the sha256. Copy the stanza from the job log, or run `scripts/homebrew-cask.sh` on the zip. Do not cut a release from this branch.

```ruby
cask "refill" do
  version "0.1.1"
  sha256 "71ea976a6003d86dbaae31e67ee1f3a8e55e257391c358f2e15f7ff2d6b5f2fd"

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

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Refill.app"],
                   must_succeed: false
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
```

Commands a user runs:

```bash
brew install --cask stepanblaha/tap/refill
curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/install.sh | bash
```

By hand: download `Refill.zip` or `Refill.dmg`, move Refill to Applications, then **System Settings → Privacy & Security → Open Anyway**, or `xattr -dr com.apple.quarantine /Applications/Refill.app`.

## What this environment could not do

This machine is Linux. There is no Swift toolchain and no Mac, so `swift test` was not run, `scripts/package.sh` was not run, and Gatekeeper was not exercised. `bash -n` passed for the shell scripts. `zsh -n` passed for `scripts/package.sh` and `scripts/release.sh`. The release parser in `scripts/install.sh` was checked against the live v0.1.1 API body and against a two-asset fixture, compact and pretty-printed. The downloaded 0.1.1 dmg's sha256 matches the cask. `npm run build` in `site/` succeeded. In a browser, the Download section shows the three options on a desktop width and at 390px, the header Download link scrolls to `#download`, the latest-release line reads v0.1.1, and the console had no errors.

## What Štěpán does next

1. Merge the Refill PR. Open the homebrew-tap PR with the cask in the section above (this agent could not push to that repo), then merge it.
2. On a Mac that has not seen the app, run the brew command and the curl installer.
3. The next time there is something to ship, `scripts/release.sh` uploads the zip and the checksums. Then move `Casks/refill.rb` from `Refill.dmg` to `Refill.zip`.
4. Optional: edit the v0.1.1 GitHub release body and delete the sentence that says the notch banner grows to fit. The changelog on this branch already dropped it.

The sections below are earlier handoffs. Where they disagree with this one, this one is current. In particular: do not cut 0.1.1 again, do not treat the notch layout writeup as the code in the tree, and do not wait to add the cask.

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

**Not the current code.** PR #3 (`b171b88`) restored the original fixed pill. `NotchLayout.swift` is not in the tree. The writeup below describes a layout that was merged and then removed before 0.1.1. Do not rebuild it from these notes.

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
- **The Homebrew tap.** https://github.com/StepanBlaha/homebrew-tap is separate. The cask is added in the unsigned-installs section above. This bullet used to say to wait for 0.1.1's dmg.

## What Štěpán does next

0.1.1 is already tagged. The install work and the cask are in the unsigned-installs section at the top of this file. Do not run `scripts/release.sh 0.1.1` again.

Still open from the release kit, if it was never set: the repo About box (gear on the repo home).

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

The cask to paste is gone. `Casks/refill.rb` is in the homebrew-tap PR described at the top. On the next release, regenerate it with `scripts/homebrew-cask.sh build/Refill.zip`.
