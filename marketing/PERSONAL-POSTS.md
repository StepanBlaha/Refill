# Personal launch posts (Štěpán Bláha)

Your own accounts: X @StepanBlaha · IG @stepa15.b · LinkedIn /in/stepan-blaha.

These are more personal than the Refill posts in `PLAYBOOK.md` and `LAUNCH.md`. The product story stays the same: a menu bar app that watches AI limits. Don't claim Refill is your first Mac app.

Media, when you have it (`marketing/media/README.md`):

- `notch-reset.gif` or `branding/og-1200x630.png` for X and LinkedIn
- `menu-bar.gif` as a follow-up
- `branding/icon-1024.png` if a post needs a picture and nothing else is recorded

---

## X bio (max 160 characters)

**Option A:**

```
Front-end dev in Prague · React & TypeScript · building Refill, a Mac menu bar app that watches AI usage limits
```

**Option B:**

```
I build interfaces with React & TS. Also shipping Refill: Claude and Codex limits in your Mac menu bar. Prague.
```

**Option C:**

```
Front-end developer · Refill, a free open-source Mac app for AI usage limits · Prague
```

Other fields:

- **Name:** Štěpán Bláha
- **Location:** Prague, Czech Republic
- **Website:** https://stepanblaha.github.io/Refill/ during launch week, then back to your own site
- **Pinned post:** the thread below

---

## X thread

Post it the afternoon of launch day, after Show HN. Image on the first post: the social card, or the notch GIF once it exists.

```
1/ I kept hitting a Claude or Codex limit mid-task and then guessing when it would reset.

So I shipped Refill: a menu bar app that watches those limits and tells me when they refill. Free and open source.
```

```
2/ It reads the Claude Code logins already on the Mac, and Codex from local session logs. Copilot, Cursor and Gemini show up too if they're installed.
```

```
3/ When a window refills, Drip (a small tank) slides out of the notch. You can also get a notification, a sound, or a webhook. It warns before the tank is empty.
```

```
4/ No Refill account and no telemetry. Usage stays in ~/.config/refill. Codex never leaves the machine.
```

```
5/ The part that took the longest was the notch on a real MacBook: a long message used to spill out of the pill. It measures the line and grows now.
```

```
6/ macOS 14+. It isn't notarized yet, so the first open needs System Settings → Privacy & Security → Open Anyway.

→ stepanblaha.github.io/Refill
→ github.com/StepanBlaha/Refill

Not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.
```

**Single post**, if you don't want a thread:

```
Shipped Refill, a macOS menu bar app that watches Claude, Codex and the other AI limits I actually hit, and says when they reset.

Free and open source → stepanblaha.github.io/Refill
```

**Later in the week:**

- "Refill, day 2: the thing people asked for first is …"
- A before/after of the notch pill if you still have a clip of the overflow.

---

## Instagram (@stepa15.b)

Most of the audience is Czech. Lead in Czech, add one English line.

```
Udělal jsem aplikaci do menu baru na Macu.

Jmenuje se Refill. Hlídá limity u Claude a Codexu (a pár dalších) a řekne, když se okno znovu naplní. Žádný účet, data zůstávají v Macu.

Je zdarma a open source. Odkaz v biu.

EN: A menu bar app that tells you when your AI limits reset. Free, link in bio.

#refill #macos #buildinpublic
```

For launch week, put `https://stepanblaha.github.io/Refill/` in the bio link.

**Stories**, if you want them:

| # | What | Text |
|---|---|---|
| 1 | The menu bar on your screen | "Dneska pouštím Refill." |
| 2 | Drip, or the social card | "Hlídá, kolik limitu ještě zbývá." |
| 3 | The notch, or a still of it | "Když se to naplní, ozve se." |
| 4 | Icon | Link sticker → the site, labelled "Refill" |

Skip the stories if you don't have a recording. One feed post is enough.

---

## LinkedIn (/in/stepan-blaha)

Post on launch day, morning Prague time. Put the Product Hunt or site link in the **first comment**, not in the post body.

### Czech

```
Jako front-end vývojář dělám denně v Reactu a TypeScriptu. Vedle toho jsem vydal malou Mac aplikaci.

Jmenuje se Refill. Vznikla z obyčejné situace: v půlce práce mi došel limit u Claude nebo Codexu a já jen odhadoval, kdy se okno znovu naplní.

Refill sedí v menu baru:
• ukáže, kolik z limitu zbývá
• ozve se, když se okno resetuje (notch, notifikace, nebo webhook)
• umí víc účtů Claude Code, Codex, a volitelně Copilot, Cursor a Gemini
• data zůstávají na Macu, žádný účet, žádná telemetrie

Je zdarma a open source (MIT).

(Refill je nezávislá aplikace. Není spojená s Anthropic, OpenAI, GitHubem, Cursorem ani Googlem.)

#macos #opensource #swift
```

### English

```
I'm a front-end developer. I also shipped a small Mac app.

It's called Refill. I kept hitting a Claude or Codex limit mid-task and guessing when the window would reset, so I put the limits in the menu bar.

• it shows what's left
• it signals when a window refills (a notch banner, a notification, or a webhook)
• Claude Code, Codex, and optionally Copilot, Cursor and Gemini
• no account and no telemetry. Usage stays on the Mac

Free and open source (MIT).

(Refill is independent and not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.)

#macos #opensource #swift
```

Reply to comments the same day.

---

## Order on launch day

1. Product Hunt goes live (`LAUNCH.md`). Post the maker comment.
2. LinkedIn, Czech. Link in the first comment.
3. Show HN in the early US afternoon, then the X thread.
4. Instagram only if you have a picture you're happy with.
5. Evening: note downloads and the first bugs. Don't post a victory lap with made-up numbers.
