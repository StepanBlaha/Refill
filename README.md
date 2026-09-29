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

## Signals (all fire on every reset)
| Sink | Details |
|---|---|
| Notification + sound | toggle/pick sound in Settings |
| Shell hook | `~/.config/refill/on-reset` (sample installed). Event JSON on stdin, `REFILL_*` env vars |
| Webhook | POST event JSON to any URL (ntfy, Slack, Home Assistant…) |
| Distributed notification | `cz.stepanblaha.refill.reset`, userInfo = `REFILL_*` keys. Other Mac apps can listen |
| Files | `~/.config/refill/status.json` (live), `events.jsonl` (history) |
| Dashboard | `http://127.0.0.1:7788` flashes green and beeps on reset. JSON at `/status` and `/events` |

## Build
```bash
scripts/build.sh --run            # build/Refill.app
scripts/build.sh --install --run  # copy to /Applications
```
