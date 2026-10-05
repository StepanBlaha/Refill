# Changelog

All notable changes to Refill are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Release notes are generated from the version section below. `scripts/release.sh` and the release workflow publish **New**, **Improved** and **Fixed** for that version, with the install blurb in front.

## [Unreleased]

## [0.2.0] - 2026-10-05

### New

- Setup guides for every integration and feature: ntfy, Pushover, Telegram, Discord, Slack, Home Assistant (with a ready-to-paste automation), Philips Hue, WLED, custom webhooks, the hook script, Shortcuts, the dashboard, widgets, quiet hours, extra Claude accounts, Copilot, Cursor and Gemini. Online at <https://stepanblaha.github.io/Refill/guides/> and in `docs/GUIDES.md`.
- Every integration in Settings has a **Setup guide** button that opens its section of the guide. Settings → Accounts links to the account guide.
- Three ways to install without notarization. Homebrew: `brew install --cask stepanblaha/tap/refill`. One line: `curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/install.sh | bash`. By hand: `Refill.zip` or `Refill.dmg`, then **System Settings → Privacy & Security → Open Anyway**, or `xattr -dr com.apple.quarantine /Applications/Refill.app`.
- Each release uploads `Refill.zip` (a ditto archive of the app, ad-hoc signed with `codesign --sign -` when nothing has signed it yet) next to `Refill.dmg`, and a `.sha256` for each. The installer checks that checksum before it replaces `/Applications/Refill.app`.

### Improved

- The landing page is redesigned: a live hero, a bento grid of sources, a pinned scroll story for signals, grouped integrations, a drawn burn-rate chart, an accordion FAQ and copy buttons for every install command. Page backgrounds are black throughout.
- The mobile menu slides open, blurs the page behind it and closes when you tap outside.

### Fixed

- The dashboard **Port** field is back in Settings → General → Dashboard.
- Copy buttons on the site always confirm, or explain the failure, instead of staying silent when the browser blocks the clipboard.

## [0.1.1] - 2026-10-04

### New

- The public landing page is finished for release: mobile menu, page titles, a 1200×630 Open Graph image, JSON-LD, breadcrumbs, `llms.txt`, icons and a 404. It is published at <https://stepanblaha.github.io/Refill/>.
- `Refill --render-og` writes that 1200×630 social banner.

### Improved

- The README is rewritten for a public release: what Refill does, how to install it, which sources it reads, how signals work, and how to build it.
- First-launch instructions match current macOS: the app is not notarized, so open it and use **System Settings → Privacy & Security → Open Anyway**, or `xattr -dr com.apple.quarantine /Applications/Refill.app`.

### Fixed

- The menu, the dashboard toast and the landing-page status pill wrap instead of overflowing.

## [0.1.0] - 2026-09-30

First release.

### New

- Menu bar app for macOS 14+ that reads Claude Code limits (every login under `~/.claude` and `~/.claude-*`: 5-hour session, week, week-Opus/Sonnet) and Codex CLI limits from local session logs, and signals when a window refills.
- Reset detection. A reset is scheduled when a known `resets_at` passes while usage was above zero (this works offline), or observed when a poll shows the reset time jumped forward and usage dropped. Resets are deduped per account, window and reset time.
- Drip, the tank mascot. A refill, a warning (80% and 95% by default) or an empty tank can show a notch banner, a notification and a sound.
- Signals you wire up yourself: a shell hook, ntfy, Pushover, Telegram, Discord, Slack, Home Assistant, Philips Hue, WLED and a custom webhook. Quiet hours can mute the sound.
- Shortcuts via `refill://`, a local dashboard on `127.0.0.1:7788`, menu bar widgets, and a burn-rate history per tank.
- Optional sources, off unless they look installed: GitHub Copilot, Cursor and Gemini CLI.
- An iPhone companion that reads the dashboard on the local network.
- First-run onboarding, launch at login from `/Applications`, per-account hide and show, and an in-app check for a newer GitHub release.
- A drag-to-Applications disk image (`Refill.dmg`), the MIT license, and a privacy policy, terms and third-party notices.
- A first marketing site (Next.js, static export) and `Refill --render` snapshots of the menu, moods, settings, history and accounts.

### Improved

- Dark panels, one green accent and a short voice for Drip. Errors say what to do next.
- HTTP 429 pauses that account (`Retry-After`, otherwise 15 minutes). Renewing an expired Claude login can be turned off so Refill does not race Claude Code for a refresh token.
