# Security Policy

## Supported versions

Only the latest release of Refill receives security fixes.

| Version | Supported |
|---|---|
| 0.1.x | ✅ |
| older | ❌ |

## What matters most

Refill keeps provider logins on your Mac and sends them only to the service they belong to. We especially want to hear about:

- a Claude, Codex, Copilot, Cursor or Gemini token leaving the place it was read from: logs, `~/.config/refill` files other than the ones you configured, the pasteboard, or a crash report
- `~/.config/refill/integrations.json` (webhooks, bot tokens, API keys) being created world-readable. It should be mode `0600`
- the local dashboard answering on the network when "Visible on Wi-Fi" is off, or exposing anything other than usage status
- network requests going anywhere other than the provider you signed in to, or an integration you configured yourself
- the widget or the shared App Group container exposing data to other apps

Codex usage is requested from `chatgpt.com` with the access token in that home's `auth.json` (or the `Codex Auth` Keychain item). An expired token is refreshed at `auth.openai.com` and written back to the same place. Session logs are only a fallback and are not uploaded. A bug that sends those logs, or a Codex token, anywhere else matters too.

## Reporting a vulnerability

Please **don't open a public issue** for security problems.

- Preferred: [report it privately on GitHub](https://github.com/StepanBlaha/Refill/security/advisories/new).
- Or email **stepa15.b@gmail.com** with "Refill security" in the subject.

Include the Refill version (the menu bar → About, or the app's version string), your macOS version, the steps to reproduce, and what you expected to happen. Don't include live tokens, webhook URLs or session files. You'll get a reply within 7 days. We'll agree on a fix and a disclosure date with you, and credit you in the release notes if you'd like.

## If a token is exposed

Revoke it at the provider, then sign in again so Refill picks up the new login.

- **Claude Code:** sign out and back in, or rotate the credential Claude Code stores in the Keychain.
- **Codex:** run `codex login` in that home (`CODEX_HOME` if it is not `~/.codex`).
- **GitHub Copilot:** `gh auth refresh`, or replace the token in `~/.config/github-copilot/`.
- **Cursor and Gemini CLI:** sign in again in that app. Refill only reads the login that app already stored.
- **Integrations:** delete the webhook or bot token in Settings → Integrations, and revoke it at that service.
