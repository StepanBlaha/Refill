# Refill: Mac App Store listing

Character limits are checked; see the counts in brackets. Refill is distributed today as a GitHub dmg, not as a store build. This listing is ready for when a signed build exists. See the review notes.

## Name (max 30)
`Refill` [6]

## Subtitle (max 30)
`Your AI tanks, watched.` [23]

## Promotional text (max 170)
`Refill watches Claude, Codex, Copilot, Cursor and Gemini limits from the menu bar and signals the moment one resets. A notch, a notification, or a hook you set.`

[160]

## Description (max 4000)
```
Refill is a menu bar app that watches the AI subscription limits you already pay for and signals the moment one resets.

It lives in the menu bar. Each account is a tank: a thin bar for what is left, and Drip, a small glass tank whose face follows the lowest window. When a window refills, Drip says so. It also warns as you cross the thresholds you set (80% and 95% by default) and when a tank hits empty.

THE MENU BAR
Claude Code (every login on the Mac: the 5-hour session, the week, and the weekly model windows), Codex from local session logs, and, when those tools are installed, GitHub Copilot, Cursor and Gemini CLI.

THE NOTCH
Drip slides out of the MacBook notch with a short line in plain language. Turn it off if you would rather not.

HISTORY
A burn-rate chart per tank, so you can see whether the current pace hits empty before the reset.

SIGNALS YOU TURN ON
A notification, a sound, and a shell hook. Phone (ntfy, Pushover, Telegram), chat (Discord, Slack), lights (Home Assistant, Hue, WLED), or a webhook you write. Nothing sends until you configure it. Quiet hours can mute the sound.

ALSO
A local dashboard, menu bar widgets, an iPhone companion that reads that dashboard on your Wi-Fi, and a check for a newer GitHub release.

PRIVATE BY DESIGN
There is no Refill account, no telemetry and no Refill server. Usage, history and settings stay in ~/.config/refill on your Mac. Tokens are sent only to the provider they belong to, and to integrations you configure yourself. Codex is read from local files only. Refill does not send prompts or spend quota.

REQUIREMENTS
macOS 14 or later. Refill reads logins you already have. It does not ask you to create a Refill account.

Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.
```

## Keywords (max 100 chars, comma-separated, no spaces)
Do not repeat the app name or the category words Apple already indexes.
```
menubar,notch,usage,limits,quota,reset,claude,codex,widget,tracker,tank,session
```
[79 chars]
"claude" and "codex" are descriptive and review-sensitive, the same way a Notion client has to think about the word "notion". If review objects, drop them and keep `menubar,notch,usage,limits,quota,reset,widget,tracker,tank,session`.

## What's New: 0.1.1
```
The public site and a 1200×630 social card. Same menu bar tanks, same reset signal, same local-only history.
```

## Categories
- Primary: Utilities
- Secondary: Developer Tools

## Age rating answers
All "None" / "No": cartoon or fantasy violence, realistic violence, sexual content, profanity, horror, mature themes, alcohol/tobacco/drugs, gambling, contests, medical advice, unrestricted web access (Refill talks only to the provider APIs for accounts the user already signed into, and to integrations the user configured), user-generated content shared between users (No: nothing is posted anywhere by the app). Expected rating: **4+**.

## App Privacy: "Data Not Collected"
- Refill has no server of its own. The developer receives nothing.
- Provider tokens stay on the Mac (Keychain items the provider's own CLI created, or local credential files). Refill reads them to ask that provider for usage.
- Usage, history and settings are files in `~/.config/refill`. They are not uploaded.
- Calls to a provider, or to a phone, chat, light or webhook the user configured, are the user sending their own data to a service they chose. That is not collection by the developer.
- No analytics, advertising, crash reporting or telemetry SDKs.
- The only network call Refill makes for itself is the daily check of GitHub Releases for a newer version. That request does not include usage or account contents.
- Answer every data-type question "No" and set the label to **Data Not Collected**. Tracking: **No**.

## URLs
- Support URL: https://github.com/StepanBlaha/Refill/issues
- Marketing URL: https://stepanblaha.github.io/Refill/
- Privacy Policy URL: https://stepanblaha.github.io/Refill/privacy/
- Support email: stepa15.b@gmail.com
- Copyright: 2026 Stepan Blaha

## Review notes (suggested)
Refill is an independent menu bar client. It is not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google. The current public build is a GitHub dmg and is not notarized; a store submission needs a signed, notarized build, which this repo does not produce yet.

For review, a Mac with Claude Code or Codex already signed in is enough, or the in-app preview: `Refill --render` draws the menu, settings, history and accounts from sample accounts (`stepan@example.cz`, `work@example.cz`). Settings → General → Preview notch shows the banner. Settings → General → Send test fires a local signal. No demo account is shared here, and the app has no Refill login to hand out.

## Screenshot shot list (2880×1800)
The files in `marketing/screenshots/` are HTML stand-ins until you record them on a Mac (`scripts/capture-marketing.sh`). Captions are white, on a dark desktop. Sample accounts only.

1. **Menu bar** (`01-menu-bar.png`). The panel open under the menu bar icon. Caption: "Your AI tanks, watched."
2. **Notch** (`02-notch-reset.png`). Drip in the notch, "Tank's full". Caption: "The moment it refills."
3. **History** (`03-history.png`). Burn-rate chart. Caption: "Will this pace hit empty?"
4. **Settings** (`04-settings.png`). Notifications, sound, the notch, quiet hours. Caption: "Signals, the way you want them."
5. **Accounts** (`05-accounts.png`). Detected logins. Caption: "The logins already on your Mac."
6. **Moods** (`06-moods.png`). Drip's five faces. Caption: "Drip keeps watch."

`Refill --render` also writes borderless UI stills: `menu.png`, `moods.png`, `settings.png`, `history.png`, `accounts.png`. Those are the files to swap in once the app has drawn them.

Do not put a provider logo on the icon or in the corner of a shot as if it were Refill's. The non-affiliation line in the description stays.
