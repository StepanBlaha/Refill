# Refill — Brand Guide

## Name

**Refill** is a menu bar app for macOS that watches your AI subscription limits and signals the moment one resets.

- Always written **Refill**, with a capital R. Never "REFILL", "refill app" or "Refill for Claude".
- **Drip** is the mascot, a flat glass tank with a face. Always capital D. Drip is not a separate product.
- The bundle id is `cz.stepanblaha.refill`. Local data lives in `~/.config/refill`.
- **Provider rule:** don't put Claude, Codex, Copilot, Cursor, Gemini, Anthropic, OpenAI, GitHub or Google in the product name, the app icon, the domain or social handles. You can say "works with Claude Code and Codex" under the Refill name. When those names appear, keep the line: "Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google."
- "Refill" is a provisional name. A trademark search (USPTO, EUIPO, ÚPV) has not been done yet. See [TRADEMARKS.md](../TRADEMARKS.md).

## Taglines

- Primary: **Your AI tanks, watched.**
- Alternatives:
  - "The moment it refills."
  - "Menu bar limits for Claude, Codex and the rest."
  - "Lives in your menu bar. Costs nothing."

## Voice

Two registers.

**Drip, in the app.** Short, a little cheeky, never corporate. Say what happened and what to do.

| Say | Don't say |
|---|---|
| "Tank's full." | "Awesome! Your usage window was successfully reset!" |
| "Claude has burned 80% of the 5h session. Refill in 40m." | "Uh oh! You're almost out of tokens!!!" |
| "Not seeing Codex? Use it once so a session log exists." | "An unknown error occurred." |

**Public writing** (site, README, release notes, stores). Plain and short. No hype words, no "revolutionary", no begging for upvotes. The non-affiliation line and the first-launch note stay in anything that tells people to install.

## Visual identity

Tokens live in `Sources/Refill/Theme.swift` and `site/src/app/globals.css`.

- **Surface:** pure black (`#000000`). Panels are `#1C1C1E`, raised rows `#2C2C2E`.
- **Text:** white (`#FFFFFF`), secondary `#808080`, tertiary white at 32% opacity.
- **Hairline:** white at 10% opacity.
- **Accent:** green `#30D158`. This is the "full enough" color. One accent, no glow.
- **Status:** warning `#FF9F0A` (about 70% used and up), danger `#FF453A` (about 90% and up, and an empty tank).
- **Type:** the system font (SF Pro). Digits in percentages are tabular.
- **Shape:** 4px radius on controls, 8px on panels. The menu bar glyph is a 12×16 tank, template-black, filled to the lowest remaining window.
- **Motion:** unfold spring (response 0.62, damping 0.72) and a contents spring (0.48, 0.8), the same springs the notch uses. Honor Reduce Motion on the website.

## Drip

Drip is a flat tank: a cap, a rounded glass, a liquid level, and a face. The liquid is the remaining quota. The face is the mood.

| Mood | When | Liquid |
|---|---|---|
| Happy | Plenty left | Green, high |
| Focused | Around half | Amber |
| Sweaty | Running low | Red, low |
| Asleep | Empty | Faint, almost gone |
| Party | Just refilled | Green, full, a small hop |

Don't redraw Drip as a water drop, a bottle logo, or a character with limbs. Don't put a provider logo on the glass. Small drops (`DropletShape`) are only for sweat and tiny icons.

## App icon

- Source artwork: `branding/icon-1024.png` (1024×1024). It is a black squircle (824pt, continuous corner radius 185, a 6px white hairline at 12% opacity) with Drip happy at about 72% full.
- `branding/AppIcon.icns` and `branding/AppIcon.iconset/` are generated from that PNG:

  ```bash
  python3 branding/make_icns.py   # needs Pillow
  ```

- The built app does **not** load the icns directly. Xcode compiles `Resources/Assets.xcassets` (`CFBundleIconName` = `AppIcon`), which is how the Brink app is wired too. Regenerate the asset-catalog PNGs from `icon-1024.png` if the artwork changes, and keep them in sync with the icns.
- Don't use SF Symbols in the icon. Apple's license allows them in the running app, not in icons or logos.
- The social card is `branding/og-1200x630.png` (also `site/public/og.png`), from `Refill --render-og`.

## Writing the providers

- Say the product names the way their owners do: Claude Code, Codex, GitHub Copilot, Cursor, Gemini CLI.
- Don't use their logos as if they were Refill's, and don't recolor Drip in their brand colors.
- Any website, store listing or launch post states: *"Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google."*
