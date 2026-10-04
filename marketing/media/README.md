# Media to record

GIFs are not in the repo yet. `Refill --render` runs on a Mac and writes still PNGs, not animation, and it does not draw the notch. Record the clips below on a Mac, with sample or demo accounts (the `--render` snapshots use fake emails). Don't record a real token, a real webhook or a full email address.

Save stills in `marketing/screenshots/` and GIFs in `marketing/media/`.

## Stills from the app

```bash
swift build
.build/debug/Refill --render marketing/screenshots
.build/debug/Refill --render-og branding/og-1200x630.png
.build/debug/Refill --render-icon branding/icon-1024.png
```

That writes:

| File | What it is |
|---|---|
| `menu.png` | Menu bar panel: Drip and the sample Claude and Codex tanks |
| `moods.png` | Drip's five moods in a row |
| `settings.png` | Settings |
| `history.png` | Burn-rate history |
| `accounts.png` | Accounts tab |
| `branding/og-1200x630.png` | 1200×630 social card |
| `branding/icon-1024.png` | App icon source |

## Screen recordings still needed

| Save as | What to capture |
|---|---|
| `menu-bar.gif` | The menu opening, tanks updating, Drip changing face as a window drains |
| `notch-reset.gif` | Drip sliding out of the notch when a window refills. A short line and a long line, so the top pill is visibly tall enough |
| `notch-warning.gif` | A warning (amber) and an empty tank (red) |
| `history.gif` | Opening history and the burn-rate chart |
| `install.gif` | Opening `Refill.dmg` and dragging Refill to Applications |

Keep each GIF under about 8 seconds. The notch clip is the one launch posts should lead with.
