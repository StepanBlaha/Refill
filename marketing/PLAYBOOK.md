# Refill marketing playbook

Where Refill gets talked about, in one place: who it's for, which channels, a launch week, and where the ready-to-copy posts live.

**Related files:**

- `marketing/LAUNCH.md`: Product Hunt, Show HN, r/macapps, r/ClaudeAI
- `marketing/LISTINGS.md`: directory entries and the Homebrew cask
- `marketing/APPSTORE.md`: Mac App Store copy, for when a signed build exists
- `marketing/PERSONAL-POSTS.md`: Štěpán's own accounts
- `marketing/social/README.md`: carousel, stories, reel, square video
- `marketing/media/README.md`: stills, GIFs, and which files are HTML stand-ins
- `branding/BRAND.md`: name, Drip, colors, voice

---

## 1. The basics

**One sentence:** Refill is a menu bar app for macOS that watches your AI subscription limits and signals the moment one resets.

**The story:**

> I kept hitting a Claude or Codex limit mid-task and guessing when it would come back. So I built a menu bar tank that tells me.

**Who it's for:**

1. **People who live in Claude Code or Codex** and actually feel the 5-hour window.
2. **Mac menu bar people** who already run a notch or a stats app and will try a free native one.
3. **Developers who read Hacker News and r/swift**, who care that Codex is local-only and there is no telemetry.

**Three things to repeat:**

| Point | Proof |
|---|---|
| **It notices the reset** | Scheduled from `resets_at` (works offline) or observed when usage drops and the reset time jumps |
| **It's in the menu bar** | Drip, the tanks, a notch banner, a notification |
| **It stays on the Mac** | `~/.config/refill`, no account, no Refill server. MIT source |

**Always:**

- "Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google."
- "Not notarized. First launch: System Settings → Privacy & Security → Open Anyway."
- The link: **https://stepanblaha.github.io/Refill/**
- **Voice:** short. No "revolutionary". No exclamation-mark hype. No asking for upvotes.

**Never:**

- Put a provider logo on the icon or imply Refill is official.
- Call it "Claude Refill" or similar.
- Paste a real token, webhook or email into a screenshot.
- Buy upvotes.

---

## 2. Channels

| Channel | Why | Priority |
|---|---|---|
| **Product Hunt** | One launch day, a page you can link later | High |
| **Show HN** | Developers, stars, hard questions about the undocumented APIs | High |
| **r/macapps** | People who install menu bar apps | High |
| **r/ClaudeAI** | The people who hit the 5-hour limit. Follow their promo rules | High |
| **r/swift, r/SwiftUI, r/opensource** | The implementation, after the launch posts | Medium |
| **X / Bluesky / Threads** | One image, the site link, then replies | Medium |
| **LinkedIn and Instagram** | Personal network. Copy is in `PERSONAL-POSTS.md` | Medium |
| **Awesome lists and directories** | Slow traffic. `LISTINGS.md` | Medium |
| **Homebrew tap** | `brew install --cask stepanblaha/tap/refill` | Medium |

Short video: `marketing/media/notch-reset.gif` and `marketing/social/reel.mp4` are in the repo as HTML stand-ins. Use them so a post is not blocked, and replace the GIF with a Mac recording (`scripts/capture-marketing.sh`) when you have one. The social card is still enough for day one.

---

## 3. Launch week

### Before

- [ ] Install the dmg on a Mac that has never seen the app. Walk the Open Anyway step yourself.
- [ ] Confirm Claude and Codex both show a tank, and that a test signal fires (Settings has a test for integrations).
- [ ] Product Hunt maker account, a Hacker News account you've actually commented from, and a read of the Reddit rules.
- [ ] Five people who will try it and reply honestly. Not to upvote.

### The week

| Day | Do |
|---|---|
| **Launch morning** | Product Hunt goes live at 00:01 Pacific. Post the maker comment from `LAUNCH.md`. Reply all day. |
| **Launch afternoon** | Show HN, then the short X / Bluesky post. Personal LinkedIn post (`PERSONAL-POSTS.md`). |
| **Next day** | r/macapps. Fix anything that blocked an install. |
| **Day 3** | r/ClaudeAI, in the form their rules allow. r/swift if the technical post is ready. |
| **Later that week** | One or two awesome-list PRs. Write down downloads and the top three complaints. |

### The following weeks

- Ship a patch if the complaints are real, and say so in the original threads.
- Add the Homebrew cask (`scripts/homebrew-cask.sh`) to https://github.com/StepanBlaha/homebrew-tap.
- Record the GIFs in `marketing/media/README.md` and add them to the posts that are still getting comments.
- Reply to GitHub issues. Tag small ones `good first issue` when they really are.

---

## 4. Profiles

**Bio:**

```
Refill: your AI limits, in the macOS menu bar.
Free · open source · macOS 14+
stepanblaha.github.io/Refill
```

**Picture:** `branding/icon-1024.png`. **Link:** https://stepanblaha.github.io/Refill/

Personal bios (X, Instagram, LinkedIn) are in `PERSONAL-POSTS.md`. Those accounts stay personal. This bio is for a Refill account, if you make one.

---

## 5. Replies

| They say | You reply |
|---|---|
| "Is this official?" | "No. Independent app. It reads the login you already have, and it isn't affiliated with the providers." |
| "Will this get me banned?" | "It uses undocumented usage endpoints, the same kind of call your own tools make, and it doesn't send prompts. A provider can still restrict that. The README says so." |
| "Unidentified developer" | "It isn't notarized yet. System Settings → Privacy & Security → Open Anyway, once. Notarization is the next install fix." |
| "Is my data safe?" | "There's no Refill server. Usage stays in ~/.config/refill. Tokens only go to the provider they belong to. Codex never leaves the Mac. The code is MIT, so you can check." |
| "Windows?" | "Mac only. The menu bar and the notch are the product." |
| "Feature, please" | "Good idea. I opened an issue: [link]." |
| A bug | "Thanks. Tracking it here [link]." Then fix it. |
| Harsh criticism | "Fair. I'll look at [the specific part]." |

---

## 6. What to write down

Refill and the site have no analytics on purpose. Once a week, note:

- GitHub release downloads, stars, issues opened and closed.
- Product Hunt comments worth keeping.
- The three most common requests and the three most common failures. Those pick the next version.

**A useful first month:** people who aren't you running it, a handful of real bug reports, and one directory or Homebrew install that works. Don't invent a download target.

---

## 7. Money

| Item | Note |
|---|---|
| Apple Developer Program (notarization) | The install step everyone trips on. Worth it before a bigger push. |
| Product Hunt, HN, Reddit, awesome lists | Free. |
| Ads and paid upvotes | Skip. |

Press page for anyone who asks for a logo and a boilerplate: https://stepanblaha.github.io/Refill/press/
