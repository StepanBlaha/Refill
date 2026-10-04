# Refill launch kit

**Current facts** (keep posts consistent with these):

- **What it is:** a menu bar app for macOS that watches your AI subscription limits and signals the moment one resets.
- **Price and license:** free, open source (MIT). The name Refill, the Drip mascot and the app icon are not part of the license.
- **Requirements:** macOS 14 Sonoma or later. It reads logins you already have: Claude Code, Codex CLI, and optionally GitHub Copilot, Cursor and Gemini CLI.
- **What it signals:** a notch banner (Drip slides out), a notification, a sound, plus the hooks you turn on (phone, chat, lights, webhook, shell). Warnings at 80% and 95%, and when a tank hits empty.
- **Privacy:** no Refill account, no telemetry, no Refill server. Usage stays in `~/.config/refill`. Tokens go only to the provider they belong to.
- **Links:** site https://stepanblaha.github.io/Refill/ · repo https://github.com/StepanBlaha/Refill · download https://github.com/StepanBlaha/Refill/releases/latest/download/Refill.dmg
- **Not notarized:** first launch needs **System Settings → Privacy & Security → Open Anyway**, or `xattr -dr com.apple.quarantine /Applications/Refill.app`. Say it up front.
- **Always include:** "Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google."

**Media:** GIFs are not recorded yet. See `marketing/media/README.md` for the stills `Refill --render` can write and the clips to capture (menu bar, notch refill, a long notch line, history, install). Until those exist, use `branding/og-1200x630.png` and `branding/icon-1024.png`.

**Voice:** short, honest, a little dry. No hype words, no asking for upvotes.

---

## 1. Product Hunt

**Where:** https://www.producthunt.com/posts/new. Make a maker account a few days before.

**When:** Tuesday, Wednesday or Thursday. Submit so it goes live at **00:01 Pacific** (09:01 Prague in summer, 08:01 in winter). Stay online that day to reply.

**How:**

1. **Name:** Refill
2. **Tagline** (max 60 characters): `Your Claude and Codex limits, watched in the menu bar`
3. **Links:** https://stepanblaha.github.io/Refill/ and https://github.com/StepanBlaha/Refill
4. **Topics:** Mac, Open Source, Artificial Intelligence, Developer Tools, Productivity.
5. **Thumbnail:** `branding/icon-1024.png` (export 240×240 if the form asks).
6. **Gallery**, once the recordings exist, in this order:
   1. `marketing/media/notch-reset.gif`
   2. `marketing/screenshots/menu.png`
   3. `marketing/media/menu-bar.gif` or `marketing/screenshots/history.png`
   4. `marketing/screenshots/settings.png`
   5. `branding/og-1200x630.png`
7. **Pricing:** Free. Tick "Open source" if the form offers it.
8. **Description** (max 260 characters):

```
Refill sits in your Mac menu bar and watches Claude, Codex, Copilot, Cursor and Gemini limits. When a window refills, Drip (a small tank) says so: notch, notification, sound, or a hook you set. Free and open source. No account.
```

**Maker comment** (post it in the first minute):

```
Hi Product Hunt.

I kept hitting the 5-hour Claude window, or a Codex limit, in the middle of something, and then guessing when it would come back. So I built Refill: a menu bar tank for the limits I already pay for.

• It reads the Claude Code logins already on the Mac (5-hour, week, Opus and Sonnet), and Codex from local session logs
• Copilot, Cursor and Gemini CLI show up too, if those apps are installed
• When a window refills, Drip slides out of the notch. You also get a notification, a sound, and whatever you wired up: phone, Slack or Discord, a light, a webhook
• It warns at 80% and 95%, and when a tank is empty. History shows whether the current pace hits empty before the reset

It's native Swift, free and MIT open source. There's no Refill account and no telemetry. Usage stays in ~/.config/refill.

Honest note: it isn't notarized yet, so the first open needs System Settings → Privacy & Security → Open Anyway.

I'd like to know which limit you actually run out of, and what's missing.

(Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.)
```

**That day:** reply to every comment. If someone hits a bug, say you're fixing it and ship a patch release. Don't ask anyone to upvote.

---

## 2. Show HN

**Where:** https://news.ycombinator.com/submit. An account with a little comment history helps. Make it a week ahead.

**When:** a weekday at **14:00–16:00 Prague** (8–10 am US East). The same day as Product Hunt, or the day after.

**Title:**

```
Show HN: Refill, a macOS menu bar app that watches AI subscription limits
```

**URL:** `https://github.com/StepanBlaha/Refill`. Hacker News prefers the repo for open-source projects.

**First comment:**

```
Hi HN. I built Refill because I kept guessing when a Claude or Codex window would reset.

It's a native macOS menu bar app (Swift, AppKit plus SwiftUI). It reads usage with the logins already on the machine: Claude Code from the Keychain, Codex from local session logs (no OpenAI request), and optionally Copilot, Cursor and Gemini. There is no Refill server, account or analytics. State lives in ~/.config/refill.

A reset is either scheduled, when a known resets_at passes (this works offline), or observed, when the reset timestamp jumps forward and usage drops. Events are deduped per account, window and reset time. HTTP 429 backs off.

The noisy part is optional: a notch banner, a notification, a sound, a shell hook, and webhooks (ntfy, Slack, Hue, and so on). The notch is a borderless panel under the hardware notch; it measures the message and grows so a long line isn't clipped.

Free, MIT licensed, macOS 14+. It isn't notarized yet (System Settings → Privacy & Security → Open Anyway the first time). The provider usage endpoints are undocumented and can change. Feedback on that, and on the reset detection, is welcome.

Not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.
```

Answer technical questions. Take criticism without arguing. Don't ask for upvotes.

---

## 3. Reddit: r/macapps

**Where:** https://www.reddit.com/r/macapps/submit. Read the sidebar. Disclose that you made the app. Use a "Free" or developer flair if the sub requires one.

**When:** the day after Product Hunt, around 15:00–17:00 Prague.

**Title:**

```
[Free, open source] I made Refill: a menu bar app that tells me when my AI limits reset
```

**Body:**

```
Hi r/macapps, I'm the developer. I got tired of guessing when a Claude or Codex window would refill, so I built a menu bar app for it.

Refill shows how much of each limit is left. When one resets, a small tank mascot (Drip) slides out of the notch, and you can also get a notification, a sound, or a webhook.

• Claude Code (every login on the Mac) and Codex CLI
• Copilot, Cursor and Gemini CLI if they're installed
• Warnings before you hit empty, and a burn-rate chart
• Optional: phone push, Slack/Discord, Hue, a shell hook
• Nothing phones home. No account, no telemetry

Native Swift, macOS 14+, free and MIT.
Download: https://stepanblaha.github.io/Refill/

It's not notarized yet. First launch: System Settings → Privacy & Security → Open Anyway.
Not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google. Happy to hear what breaks.
```

Attach `notch-reset.gif` or `menu-bar.gif` once they exist. Until then, the post can ship with `branding/og-1200x630.png`.

---

## 4. Reddit: r/ClaudeAI

**Where:** https://www.reddit.com/r/ClaudeAI/submit. Read the rules. Self-promotion is often limited to a weekly thread or a flair. If that's the case, post there instead of a standalone link.

**When:** day 2 or 3.

**Title:**

```
I kept hitting the 5-hour Claude limit mid-task, so I made a free Mac menu bar app that tells me when it resets
```

**Body:**

```
Refill watches the Claude Code logins already on your Mac (the 5-hour session, the week, and the Opus/Sonnet week) and pings you when a window refills. It can also show Codex, Copilot, Cursor and Gemini.

It uses the same local Claude Code login, polls usage, and stays quiet until something changes. Optional notch banner, notification, sound, or a webhook. No Refill account. Data stays in ~/.config/refill.

https://stepanblaha.github.io/Refill/

It's an independent app, not affiliated with Anthropic. The usage endpoint is undocumented and can change. macOS 14+, free, open source. Not notarized: Open Anyway on first launch.
```

A Codex or ChatGPT coding community is worth a shorter version of the same post the day after, if that sub allows developer posts. Lead with Codex being read offline from session logs, and keep the non-affiliation line.

---

## 5. Also worth a post

| Where | Angle | When |
|---|---|---|
| **r/macapps** already covered | The install story and the notch | Day 2 |
| **r/swift, r/SwiftUI** | Reset detection, the notch panel that grows with the text, no third-party packages. Link the repo | Day 3+ |
| **r/opensource** | MIT menu bar app, what it does and does not send off the Mac | Day 3+ |
| **X / Bluesky / Threads / Mastodon** | One image or the notch GIF, and the site link. Hashtags #buildinpublic #macOS #indiedev | Launch day |
| **LinkedIn** | Personal story. See `marketing/PERSONAL-POSTS.md` | Launch week |
| **Indie Hackers** | "Shipped a free Mac app for AI limits", with real numbers after a week | Week 2 |

**Short post:**

```
I kept guessing when my Claude or Codex window would reset.

Refill sits in the macOS menu bar and says when it refills. Free and open source.

https://stepanblaha.github.io/Refill/
```

---

## After launch

- **Within a couple of days:** fix the top reported bugs, ship a patch, and say what changed in each thread. The notes come from `CHANGELOG.md`.
- **Numbers worth writing down:** GitHub release downloads, stars, and issues. Refill has no analytics. The site doesn't either.
- **Directories:** the lists in `marketing/LISTINGS.md`, a few a week. Homebrew comes after you add the cask to the tap (see that file).
