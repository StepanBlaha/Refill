import type { Section } from "./types";

export const sources: Section[] = [
  {
    id: "accounts", title: "Claude and Codex accounts", group: "Sources",
    intro: "Refill finds the Claude Code and Codex logins already on your Mac, and you can add more.",
    blocks: [
      { t: "h", x: "What Refill finds on its own" },
      { t: "ul", x: [
        "Claude Code: the default `~/.claude` and every `~/.claude-*` folder. Each folder is one login.",
        "Codex CLI: `~/.codex/sessions`, read offline. It updates when you use Codex. Turn it off under **Settings → Accounts → Other tools**.",
      ] },
      { t: "h", x: "Add a second Claude account" },
      { t: "ol", x: [
        "Open **Settings → Accounts**. Under **Add a Claude account**, type a name such as `work`, then click **Add**. Use letters, digits, `-` and `_`.",
        "Terminal opens with a separate Claude profile in `~/.claude-work`. Type `/login` and finish signing in.",
        "Type `/exit`, close the window, and click **Refresh** in Refill. The account appears under **Detected**.",
      ] },
      { t: "p", x: "From a clone of the repo you can do the same in a terminal. It sets `CLAUDE_CONFIG_DIR` and starts Claude Code." },
      { t: "code", copy: true, x: "scripts/add-claude-account.sh work" },
      { t: "p", x: "To use that account later, run Claude Code with its folder:" },
      { t: "code", copy: true, x: "alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'" },
      { t: "h", x: "Folders outside ~/.claude-*" },
      { t: "p", x: "Put one path per line in **Settings → Accounts → Extra config folders**." },
      { t: "h", x: "Hide, show or remove an account" },
      { t: "ul", x: [
        "Click **⋯** next to an account (or right-click it) and choose **Hide from Refill**. Hidden accounts are not checked and never alert. Bring one back under **Hidden → Show**.",
        "**Move profile to Trash…** is for extra Claude profiles only. It signs that profile out on this Mac and can be undone from the Trash. The default `~/.claude` is never offered.",
      ] },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`Not signed in. Run claude and type /login.`: that profile has no login. Do step 2 above.",
        "`Login expired. Run claude once to renew it.`: run Claude Code once in that profile. Or turn on **Settings → Accounts → Renew expired logins** so Refill renews it. Leave it off if Claude Code runs all day.",
        "`Rate limited. Next try at …`: Refill pauses that account after an HTTP 429 and retries by itself.",
      ] },
    ],
  },
  {
    id: "copilot", title: "GitHub Copilot", group: "Sources",
    intro: "Monthly premium-request and chat quota for your Copilot seat.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Install the GitHub CLI and sign in with the account that has Copilot.",
        "Refill reads the token with `gh auth token`. If `gh` is missing, it falls back to the editor login in `~/.config/github-copilot`.",
        "Check **Settings → Accounts → More providers → GitHub Copilot** is on. Click **Refresh**.",
      ] },
      { t: "code", copy: true, x: "brew install gh" },
      { t: "code", copy: true, x: "gh auth login" },
      { t: "p", x: "Refill only asks Copilot when it looks installed. Usage resets monthly. The endpoint is unofficial and can change." },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`No GitHub token (run gh auth login)`: sign in with the command above.",
        "`HTTP 401` or `403 (token rejected or no Copilot seat)`: the signed-in GitHub account has no Copilot seat. Check with `gh auth status`.",
      ] },
    ],
  },
  {
    id: "cursor", title: "Cursor", group: "Sources",
    intro: "Monthly usage for your Cursor plan, with no extra login.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Install the Cursor app and sign in to it.",
        "Check **Settings → Accounts → More providers → Cursor** is on. Click **Refresh**.",
      ] },
      { t: "p", x: "Refill reads the sign-in from Cursor's local database, `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`, in read-only mode. It then asks cursor.com for your usage. The billing cycle end is the reset." },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`Not signed in to Cursor`: open Cursor and sign in.",
        "`HTTP 401` or `403 (session expired, reopen Cursor)`: open Cursor so it renews its session.",
        "Cursor missing from the list: Refill skips it when the database file does not exist.",
      ] },
    ],
  },
  {
    id: "gemini", title: "Gemini CLI", group: "Sources",
    intro: "Per-model quota for Gemini CLI, with Pro and Flash tracked separately.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Install Gemini CLI, run it once and sign in with Google. It writes `~/.gemini/oauth_creds.json`.",
        "Check **Settings → Accounts → More providers → Gemini CLI** is on. Click **Refresh**.",
      ] },
      { t: "code", copy: true, x: "npm install -g @google/gemini-cli" },
      { t: "code", copy: true, x: "gemini" },
      { t: "p", x: "When the saved token expires, Refill refreshes it in memory and never writes it back. It needs the installed CLI to find the public OAuth client, or you can set `GEMINI_OAUTH_CLIENT_ID` and `GEMINI_OAUTH_CLIENT_SECRET`." },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`No Gemini CLI login`: run `gemini` and sign in.",
        "`Gemini token refresh failed (run gemini once)`: run `gemini` once so it renews its own login, then refresh.",
        "`Quota request failed`: Google rejected the request. Try again later.",
      ] },
    ],
  },
];
