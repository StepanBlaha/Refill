# Agent context

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
