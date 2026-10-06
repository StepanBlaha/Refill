# Refill setup

For a Mac that should track several AI subscriptions and still get a phone push when a limit resets, including while the Mac sleeps. This matches Refill 0.3.0. Shorter per-feature steps also live in [GUIDES.md](GUIDES.md) and at <https://stepanblaha.github.io/Refill/guides/>.

Refill is a menu-bar app. It has no account of its own and no server. Logins stay on the Mac.

## Install

macOS 14 (Sonoma) or newer. Refill is not notarized, so the first open needs the quarantine flag cleared. Settings in `~/.config/refill` survive a reinstall.

Homebrew:

```bash
brew install --cask stepanblaha/tap/refill
```

Update later:

```bash
brew upgrade --cask refill
```

One line, from the latest GitHub release:

```bash
curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/install.sh | bash
```

By hand: download [Refill.zip](https://github.com/StepanBlaha/Refill/releases/latest/download/Refill.zip) or [Refill.dmg](https://github.com/StepanBlaha/Refill/releases/latest/download/Refill.dmg), move **Refill** to `/Applications`, then:

```bash
xattr -dr com.apple.quarantine /Applications/Refill.app
open /Applications/Refill.app
```

Or open it once and use **System Settings → Privacy & Security → Open Anyway**.

Optional terminal status (reads `~/.config/refill/status.json`, needs `python3`):

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/StepanBlaha/Refill/main/scripts/refill -o ~/.local/bin/refill
chmod +x ~/.local/bin/refill
```

## First launch

| Thing | What you do |
|---|---|
| Menu bar tank | The percent is the lowest remaining 5-hour window across accounts. Click it to see each one. |
| Welcome tour | Welcome, tanks, notifications, phone, lights, done. Reopen from **Settings → General → Welcome tour**, or `open refill://onboarding`. |
| Notifications | Allow them. If you refused: **System Settings → Notifications → Refill**. |
| Open at login | Turns on the first time Refill runs from `/Applications`. Confirm **Settings → General → Startup**. |
| Files | Creates `~/.config/refill/` and serves a dashboard on `127.0.0.1:7788`. |

## Accounts

Claude Code and "Claude CLI" are the same thing here: one login in one config folder. A Claude account you only use on the web is invisible until you `/login` it in its own folder. An API-key (pay as you go) login has no 5-hour or weekly window, so Refill is not the tool for that.

### Claude

The default `~/.claude` is the account from a normal `claude` then `/login`. Add another from **Settings → Accounts → Add a Claude account** (name `work` becomes `~/.claude-work`) or:

```bash
mkdir -p ~/.claude-work
CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude
```

Type `/login` with the other account, then `/exit`. Refill reads the Keychain item Claude Code creates for that folder and asks Anthropic for usage. `~/.claude-*` and `~/.claude_*` are found on their own. Other paths go in **Extra Claude folders**, one per line.

```bash
alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
```

### Codex

Each Codex home is one account. Refill asks OpenAI for live usage with the ChatGPT login in that home. If the request fails, the newest session log is a fallback, and a window whose reset has already passed shows as — and last seen.

- `~/.codex` is always `codex:default`, even if `CODEX_HOME` points at it. Older history, hide state and fired alerts keep matching.
- A different `CODEX_HOME`, every `~/.codex-*` and `~/.codex_*` folder, and **Extra Codex folders** are separate accounts (`codex:` plus the absolute path).

**Settings → Accounts → Codex CLI → Add** with the name `work` creates `~/.codex-work`, remembers it, and opens Terminal:

```bash
export CODEX_HOME="$HOME/.codex-work"
codex login
codex
```

Or `scripts/add-codex-account.sh work` from a clone. A discovered `~/.codex-*` folder with no login and no session log is hidden as noise. The Add button lists the path so you see "No Codex login" before you sign in.

```bash
alias codex-work='CODEX_HOME=$HOME/.codex-work codex'
```

### GitHub Copilot

One row per `github.com` login from `gh auth status`. Add a login with `gh auth login`. Refill asks for each token with `gh auth token --hostname github.com --user <login>`.

The login Refill tracked first stays `copilot:default` (remembered as `copilotAnchorLogin`), so `gh auth switch` does not reshuffle history. Other logins are `copilot:<login>`. Enterprise hosts are skipped. A login literally named `default` that is not the anchor is `copilot:login:default`.

If `gh` has no github.com login, Refill uses the single editor token in `~/.config/github-copilot` (`apps.json` or `hosts.json`) as `copilot:default`. The Copilot editor is not multi-account.

### Gemini CLI

`~/.gemini/oauth_creds.json` stays `gemini:default`. Gemini CLI treats `GEMINI_CLI_HOME` as a home directory and writes creds to `$GEMINI_CLI_HOME/.gemini/oauth_creds.json`, not into the home itself.

**Add a Gemini account** named `work` uses `~/.gemini-accounts/work` and opens Terminal with `GEMINI_CLI_HOME` set. After you sign in, the file is `~/.gemini-accounts/work/.gemini/oauth_creds.json`.

```bash
scripts/add-gemini-account.sh work
alias gemini-work='GEMINI_CLI_HOME=$HOME/.gemini-accounts/work gemini'
```

Also picked up: `~/.gemini-*` and `~/.gemini_*` when they contain creds, and **Extra Gemini folders**. Point an extra folder at the directory that contains `oauth_creds.json`, or at a `GEMINI_CLI_HOME` whose `.gemini` child contains it. A refreshed token stays in memory and is never written back. The OAuth client is the public one from the installed CLI (or `GEMINI_OAUTH_CLIENT_ID` / `GEMINI_OAUTH_CLIENT_SECRET`) and is shared across accounts.

### Cursor

One account, id `cursor:default`. The Cursor app stores a single `cursorAuth` access token in `state.vscdb` per Mac user. Switching accounts inside Cursor replaces that login. A second Cursor account would need another macOS user. You can still rename or hide the one Refill shows.

### Names, hide, trash

**⋯ → Rename…** stores a display name for that account id (UserDefaults `accountLabels`). It is what the menu, notch, dashboard, widgets, history and notifications show. Order when you leave it blank: email, then the folder or tool name.

**Hide from Refill** skips the account before Refill reads it. There is no separate mute. **Hidden → Show** brings it back. This works for Claude, Codex, Copilot, Gemini and Cursor.

**Move profile to Trash…** is for extra Claude, Codex and Gemini folders only. The default `~/.claude`, `~/.codex` and `~/.gemini` are never offered. Copilot and Cursor have nothing to trash.

## Phone push while the Mac sleeps

The menu, the notch, sounds, lights and hooks need Refill running. They catch up about 30 seconds after the Mac wakes.

ntfy does not. With an ntfy integration enabled and **Send on → Refill** on, each refresh posts a delayed message for every window that has been used and whose reset is between 10 seconds and about 3 days away. ntfy delivers it about 30 seconds after the reset (`At` header), whether or not the Mac is awake. A weekly reset further out is scheduled once the Mac is awake inside that 3-day window. A session that starts while the Mac is off is scheduled the next time Refill sees it.

The message id is `refill-` plus 16 hex characters of SHA-256 over `accountId|windowKey`. Posting the same id replaces the pending message, so a moved reset time does not duplicate. Deleting that URL cancels it. If the Mac is awake at the reset, Refill sends the normal ntfy message now and deletes the delayed one. If the Mac slept through delivery, the delayed push already went out and the wake-time alert does not send a second ntfy message.

The token stays in `~/.config/refill/integrations.json`. `~/.config/refill/ntfy-schedule.json` (mode 0600) records what was scheduled and holds no token. The delayed text is the account's display name and the window, titled `Refilled`.

If **Also mute phone and chat pushes** is on and the delivery hour is inside quiet hours, that reset is not scheduled.

If you previously installed the external LaunchAgent, remove it. Refill now posts the same ids, and both would replace each other or double up:

```bash
launchctl bootout gui/$(id -u)/local.refill.ntfy-schedule
rm -f ~/Library/LaunchAgents/local.refill.ntfy-schedule.plist
```

Quick check that the phone accepts a delayed message (use your real topic):

```bash
curl -H "In: 30s" -H "Title: Refill test" -d "Scheduled push works" https://ntfy.sh/your-topic
```

Keeping the Mac awake (`pmset`, clamshell, a Mac that stays on) still matters for everything that is not ntfy. Power Nap does not run Refill.

## If something looks wrong

| Symptom | What to do |
|---|---|
| "Refill can't be opened" | `xattr -dr com.apple.quarantine /Applications/Refill.app`, or **Open Anyway**. |
| New `~/.claude-*` or `~/.codex-*` missing | It has no login or no session, so Refill hides the noise. Log in, or list the path under the extra-folders box to see the error. |
| `No Codex login. Run codex login in this home.` | Run `codex login` in that home. A Keychain prompt for `Codex Auth` is the login Codex already stored. |
| Same Claude account twice | It is logged into two folders. Hide one, or trash the extra profile. |
| Copilot shows one row | `gh auth status` has one github.com login, or only the editor token exists. |
| Cursor will not split | One login per Mac user. See above. |
| Gemini extra folder empty | The path is the wrong level. Use the folder that contains `oauth_creds.json`, or the `GEMINI_CLI_HOME` parent. |
| ntfy arrives twice | Boot out `local.refill.ntfy-schedule` if that agent is still loaded. |
| ntfy misses a reset more than 3 days away | Expected until the Mac is awake inside ntfy's 3-day window. |
| Alerts late after wake, except ntfy | The local notification waits until Refill's 30-second check. The scheduled ntfy push should already have arrived. |
