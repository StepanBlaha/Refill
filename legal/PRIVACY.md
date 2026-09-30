# Refill Privacy Policy

_Last updated: 2026-09-30_

Refill is a Mac menu-bar app that watches your AI usage limits and signals when they reset. It is built to keep your data on your Mac. The developer collects nothing: there is no Refill server, no account, no analytics and no telemetry.

## What Refill reads on your Mac

| Data | Where it comes from | Why |
|---|---|---|
| Claude Code login (access and refresh tokens) | macOS Keychain, items named `Claude Code-credentials*` | To ask Anthropic for your own usage |
| Claude config folders and account email | `~/.claude`, `~/.claude-*`, and the `.claude.json` in each | To find your accounts and label them |
| Codex CLI rate-limit data | Session logs in `~/.codex/sessions` | To show Codex usage, offline |

## What Refill stores

| Data | Where it is stored | Why |
|---|---|---|
| Usage snapshot, event log, history, state | `~/.config/refill/` (`status.json`, `events.jsonl`, `history.jsonl`, `state.json`) | To show gauges, trends and to notice resets |
| Integration settings and tokens | `~/.config/refill/integrations.json` (permissions 0600) | To send signals to services you set up. It may hold webhook URLs, bot tokens or API keys |
| On-reset hook script (optional) | `~/.config/refill/` | To run your own script when a limit resets |
| Widget data | App-group container shared with Refill widgets | To show usage in widgets |
| Refreshed Claude login | Written back to the same Keychain item it was read from | So Claude Code keeps working after a token refresh |
| Settings | macOS user defaults | To remember your preferences |

## Where your data goes

- **Anthropic.** `api.anthropic.com` receives your access token and returns your usage. `console.anthropic.com` receives your refresh token when the access token has expired. This is under [Anthropic's privacy policy](https://www.anthropic.com/legal/privacy).
- **Integrations you configure.** Only if you set them up: ntfy, Pushover, Telegram, Discord, Slack, Home Assistant, Philips Hue, WLED and custom webhooks. They receive the event text and color you configured, at the address you chose, and nothing more. Their handling of that data is governed by their own policies.
- **Nothing else.** No developer server, no analytics, no crash reporting, no advertising, no cookies. Credentials are never sent anywhere except the service they belong to.
- **Codex** is read from local files only. Refill makes no OpenAI request.

## Local dashboard and iPhone companion

Refill can serve a read-only dashboard on port 7788. It is off by default. When you turn on network access, **anyone on your local network can see your usage** while it is on. It never goes to the internet. The iPhone companion talks only to your Mac on the local network.

## Optional shell hook

If you choose to set an on-reset hook, Refill runs your own script when a limit resets. What that script does is your responsibility.

## Your control

- **Remove an integration** in Settings, or delete `integrations.json`.
- **Turn off the dashboard** in Settings.
- **Delete all local data:** quit Refill and delete `~/.config/refill/`. Refill never removes Claude Code's own Keychain login.
- Uninstalling the app ends everything it does.

## Data protection (GDPR)

The developer processes no personal data, so there is no controller relationship with the developer. You are the controller of the data on your Mac. Recipients of integrations are separate controllers under their own policies.

## Children

Refill is not directed at children under 13 (16 in the EU).

## Changes

Updates to this policy will be dated above and shipped with the app.

## Contact

Stepan Blaha, Czech Republic: GitHub Issues (github.com/StepanBlaha/Refill/issues)
