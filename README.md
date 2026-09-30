# Refill

Menu bar app for macOS 14+. It watches your AI subscription limits and **signals the moment a limit resets**.

## Sources
- **Claude**: every Claude Code login. The default `~/.claude` is included, plus any `~/.claude-*` dir and any extra dirs you list in Settings. Credentials are read from the Keychain item that Claude Code creates. Usage comes from `api.anthropic.com/api/oauth/usage` (5h session, week, week-Opus/Sonnet). Expired tokens are refreshed and written back to the Keychain.
- **Codex CLI**: `rate_limits` from the newest `~/.codex/sessions/**/rollout-*.jsonl`. Offline; it updates whenever you use Codex.

Add another Claude account:
```bash
scripts/add-claude-account.sh work   # CLAUDE_CONFIG_DIR=~/.claude-work claude → /login
```

## Reset detection
- **scheduled**: a known `resets_at` passes while usage was > 0. This works even when offline.
- **observed**: a poll shows `resets_at` jumped forward and usage dropped.
Resets are deduped per account + window + reset time.

## Events
`reset` (tank refilled), `warning` (used % crossed a threshold, default 80/95), `empty` (hit 100%), `test`.
Each event carries a `title` and `message` written in Drip's voice (Drip is the mascot), plus a light color (lime/amber/red).

## Signals
| Sink | Details |
|---|---|
| Notification + sound | set in Settings → General |
| Shell hook | `~/.config/refill/on-reset`. Gets event JSON on stdin plus `REFILL_KIND`, `REFILL_COLOR`, `REFILL_MESSAGE`… env vars |
| Integrations | Settings → Integrations, each with its own Test button and per-event toggles. Stored in `~/.config/refill/integrations.json` (0600) |
| Distributed notification | `cz.stepanblaha.refill.<kind>` |
| Files | `~/.config/refill/status.json`, `events.jsonl` |
| Dashboard | `http://127.0.0.1:7788`, with a "Visible on Wi-Fi" toggle for phones. Tanks, Drip, toasts and chimes. `/status` and `/events` return JSON |

Integrations:
- **Phone:** ntfy (free), Pushover, Telegram
- **Chat:** Discord, Slack
- **Lights:** Home Assistant webhook (any brand; payload has `rgb`/`color`), Philips Hue (group flash), WLED (color or preset)
- **Custom webhook:** method, headers, body template with `{{kind}} {{title}} {{message}} {{color}} {{r}} {{g}} {{b}} {{json}}` and more

Launch at login: on by default when run from /Applications (Settings → General).

Design review: `Refill --render <dir>` writes `menu.png` and `moods.png` and exits.

## Build
```bash
scripts/run-xcode.sh      # full app + widgets → /Applications/Refill.app (Xcode, team FW5CYB98R7)
scripts/package.sh        # Release .dmg in build/ (set DEVELOPER_ID / NOTARY_PROFILE to sign + notarize)
swift build && swift test # quick compile + unit tests (reset detection, parsing, integrations)
Refill --render <dir>     # design snapshots: menu, moods, settings, history, accounts
```
Companion iPhone app: `cd Companion && xcodegen generate`, then open `RefillCompanion.xcodeproj`.

Reliability: HTTP 429 pauses that account (honors Retry-After, default 15 min). "Renew expired logins" can be turned off in Settings → Accounts, so Refill never races Claude Code for a refresh token.

## Legal
- [LICENSE](LICENSE) (MIT)
- [Privacy Policy](legal/PRIVACY.md), [Terms of Use](legal/TERMS.md), [Third-party notices](legal/NOTICE.md)

Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.
