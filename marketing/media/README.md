# Media

Two kinds of file live here and in `marketing/screenshots/`.

**HTML stand-ins.** Drawn in Chrome from `scripts/marketing/stage.html` to match Drip, the menu bar panel and the notch pill. They use the sample accounts from `Refill --render` (`stepan@example.cz`, `work@example.cz`, Codex) and, on the history chart, a drawn curve. The figures on that curve (~8%/h, a 71% average peak, one reset today) are part of the drawing. They are not a measurement from a Mac. Rebuild the stand-ins with:

```bash
npm install --prefix scripts/marketing playwright-core
node scripts/marketing/render.mjs
```

**Real captures.** On a Mac, `scripts/capture-marketing.sh` overwrites the five stills `Refill --render` knows how to draw, and prints the list of GIFs and numbered shots you still record by hand. Do not record a real token, a webhook URL, or a full personal email.

Social pages (carousel, stories, the reel, the square video) are in `marketing/social/`. The script does not overwrite those.

## Stills from the app

```bash
swift build
.build/debug/Refill --render marketing/screenshots
.build/debug/Refill --render-og branding/og-1200x630.png
.build/debug/Refill --render-icon branding/icon-1024.png
```

`scripts/capture-marketing.sh` runs the first two when it finds a binary. `--render` writes:

| File | What it is |
|---|---|
| `menu.png` | Menu bar panel: Drip and the sample Claude and Codex tanks |
| `moods.png` | Drip's five moods in a row |
| `settings.png` | Settings |
| `history.png` | Burn-rate history. A new install shows "Collecting data" until Refill has sampled for about an hour. The stand-in shows a filled chart so the layout is visible. |
| `accounts.png` | Accounts tab |
| `branding/og-1200x630.png` | 1200×630 social card |
| `branding/icon-1024.png` | App icon source |

## Numbered shots (2880×1800)

Same job as Brink's shot list: a desktop, the UI, a caption. `--render` does not make these. The stand-ins are:

| File | Caption |
|---|---|
| `01-menu-bar.png` | Your AI tanks, watched. |
| `02-notch-reset.png` | The moment it refills. |
| `03-history.png` | Will this pace hit empty? |
| `04-settings.png` | Signals, the way you want them. |
| `05-accounts.png` | The logins already on your Mac. |
| `06-moods.png` | Drip keeps watch. |

## GIFs to replace on a Mac

| Save as | What to capture |
|---|---|
| `menu-bar.gif` | The menu opening, a tank draining, Drip changing face, then a refill |
| `notch-reset.gif` | Drip sliding out of the notch when a window refills. Use Settings → General → Preview notch. A short line and a long line, so the pill is visibly tall enough and nothing readable sits behind the camera |
| `notch-warning.gif` | A warning (amber) and an empty tank (red) |
| `history.gif` | Opening history and the burn-rate chart |
| `install.gif` | Opening `Refill.dmg` and dragging Refill to Applications |

Keep each GIF under about 8 seconds. The notch clip is the one launch posts should lead with.

The files with these names that are in the repo today are short HTML animations (ffmpeg), so a post can go out before the Mac recordings exist. Swap in the recordings when you have them. Do not describe the stand-in chart numbers as your own usage.
