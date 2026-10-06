# Refill directory listings

Ready-to-paste entries for app lists. Each one is a pull request on someone else's repo, or a form you fill in. Do them yourself, one or two a day.

**How to open a list PR on GitHub:**

1. Open the repo and the file named below. Click the pencil ("Edit this file").
2. GitHub offers to fork it. Accept.
3. Paste the entry in the right section. Keep alphabetical order when the list uses it.
4. **Propose changes**, then **Create pull request**, and paste the title and text below.

Links used below:

- Site: https://stepanblaha.github.io/Refill/
- Repo: https://github.com/StepanBlaha/Refill
- Icon: https://raw.githubusercontent.com/StepanBlaha/Refill/main/branding/icon-1024.png
- Social card: https://raw.githubusercontent.com/StepanBlaha/Refill/main/branding/og-1200x630.png
- Screenshot: https://raw.githubusercontent.com/StepanBlaha/Refill/main/marketing/screenshots/01-menu-bar.png
- Menu panel: https://raw.githubusercontent.com/StepanBlaha/Refill/main/marketing/screenshots/menu.png

`01-menu-bar.png` is a composed desktop shot. `menu.png` is the panel `Refill --render` writes. Both are HTML stand-ins until you replace them on a Mac. Don't link a file you have deleted.

---

## 1. open-source-mac-os-apps

**Repo:** https://github.com/serhii-londar/open-source-mac-os-apps

**File:** `applications.json`, inside `"applications": [ … ]`. The README is generated from this file. Don't edit the README by hand.

```json
{
  "title": "Refill",
  "short_description": "Menu bar app that watches AI subscription limits and signals when they reset.",
  "categories": ["menubar", "utilities"],
  "repo_url": "https://github.com/StepanBlaha/Refill",
  "icon_url": "https://raw.githubusercontent.com/StepanBlaha/Refill/main/branding/icon-1024.png",
  "screenshots": [
    "https://raw.githubusercontent.com/StepanBlaha/Refill/main/marketing/screenshots/01-menu-bar.png",
    "https://raw.githubusercontent.com/StepanBlaha/Refill/main/branding/og-1200x630.png"
  ],
  "official_site": "https://stepanblaha.github.io/Refill/",
  "languages": ["swift"]
}
```

**PR title:** `Add Refill`

**PR text:**

```
Adds Refill, a free MIT-licensed macOS menu bar app (Swift) that watches Claude, Codex, Copilot, Cursor and Gemini usage limits and signals when a window resets. No account and no telemetry.

Repo: https://github.com/StepanBlaha/Refill
Site: https://stepanblaha.github.io/Refill/
```

---

## 2. awesome-macOS

**Repo:** https://github.com/iCHAIT/awesome-macOS

**File:** `README.md`, in the menu bar or utilities section they currently use, in alphabetical order (between entries starting with "R").

```markdown
- [Refill](https://stepanblaha.github.io/Refill/) - Menu bar app that watches AI subscription limits and signals when they reset. [![Open-Source Software][OSS Icon]](https://github.com/StepanBlaha/Refill) ![Freeware][Freeware Icon]
```

**PR title:** `Add Refill`

**PR text:**

```
Refill is a free, open-source (MIT) native macOS app. It lives in the menu bar, shows Claude, Codex, Copilot, Cursor and Gemini limits, and signals when a window refills. No account, no telemetry.

Repo: https://github.com/StepanBlaha/Refill
```

---

## 3. awesome-mac (jaywcjlove)

**Repo:** https://github.com/jaywcjlove/awesome-mac

**File:** `README.md`, under **Menu Bar Tools** or **Utilities**, matching their current headings. If they also keep a Chinese README and CONTRIBUTING asks for it, add the same line there.

```markdown
* [Refill](https://stepanblaha.github.io/Refill/) - Menu bar app that watches AI subscription limits and signals when they reset. [![Open-Source Software][OSS Icon]](https://github.com/StepanBlaha/Refill) ![Freeware][Freeware Icon]
```

**PR title:** `Add Refill`

**PR text:** same as awesome-macOS.

---

## 4. Directories (forms)

| Site | What to enter |
|---|---|
| **AlternativeTo** | **Name:** Refill. **Platforms:** Mac. **License:** Free, Open Source. **Tags:** macos, menu-bar, claude, usage, open-source. Description below. |
| **MacUpdate** | Version from the latest release, free, download URL `https://github.com/StepanBlaha/Refill/releases/latest/download/Refill.dmg`, icon, description. |
| **SaaSHub** | Name, site, short description, category Developer Tools or Productivity. |
| **Indie Hackers** | Add the product, then a short launch post with real numbers. |

**Short description:**

```
Refill is a free, open-source macOS menu bar app that watches Claude, Codex, Copilot, Cursor and Gemini usage limits and signals the moment one resets. A notch banner, a notification, or a webhook you configure. No account and no telemetry.
```

**Always add:** "Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google." Mention that the first launch needs Open Anyway, because the app is not notarized.

---

## 5. Homebrew

`Casks/refill.rb` belongs in https://github.com/StepanBlaha/homebrew-tap. The stanza for 0.1.1 is in `AGENT_CONTEXT.md`. Install line, once that file is on `main` of the tap:

```bash
brew install --cask stepanblaha/tap/refill
```

0.1.1 published only `Refill.dmg`, so that cask points at the disk image. The next release also uploads `Refill.zip` and a `.sha256` for the zip and the disk image. After that release, point the cask at the zip. The release job prints the stanza (`scripts/homebrew-cask.sh build/Refill.zip`), or run it locally on the zip. The cask's `postflight_steps` clears `com.apple.quarantine`. Brink's cask does not; it only has caveats.

The official Homebrew cask list (`brew install --cask refill` with no tap) wants a notarized app and an app people already use. Submit there after notarization, not before.
