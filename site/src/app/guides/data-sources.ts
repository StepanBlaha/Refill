import type { Section } from "./types";

export const sources: Section[] = [
  {
    id: "accounts", title: "Accounts", group: "Sources",
    intro: "Refill finds the Claude Code, Codex, Copilot and Gemini logins already on your Mac, and you can add more. Cursor stays one login. You can rename any of them.",
    blocks: [
      { t: "h", x: "What Refill finds on its own" },
      { t: "ul", x: [
        "Claude Code: the default `~/.claude` and every `~/.claude-*` and `~/.claude_*` folder. Each folder is one login.",
        "Codex CLI: `~/.codex` (this keeps the account id `codex:default`), the folder in `CODEX_HOME` when that is different, and every `~/.codex-*` and `~/.codex_*` folder. Read offline from each home's `sessions` logs. It updates when you use that home. Turn every Codex home off with **Settings → Accounts → Codex CLI**.",
        "The Copilot, Cursor and Gemini sections below cover those tools.",
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
      { t: "h", x: "Add a second Codex account" },
      { t: "ol", x: [
        "Under **Codex CLI**, type a name such as `work`, then click **Add**.",
        "Terminal opens with `CODEX_HOME` set to `~/.codex-work`, runs `codex login`, then starts Codex once so a session log exists.",
        "Quit Codex, close the window, and click **Refresh**.",
      ] },
      { t: "code", copy: true, x: "scripts/add-codex-account.sh work" },
      { t: "code", copy: true, x: "alias codex-work='CODEX_HOME=$HOME/.codex-work codex'" },
      { t: "p", x: "The default `~/.codex` stays `codex:default` even when `CODEX_HOME` points at it, so history and hidden accounts from older Refill builds still match. A `~/.codex-*` folder with no sessions is hidden until you log in, unless you list it under **Extra Codex folders**. The Add button writes that path for you." },
      { t: "h", x: "Folders outside the automatic names" },
      { t: "p", x: "Put one path per line in **Extra Claude folders**, **Extra Codex folders**, or **Extra Gemini folders**. `~` is fine." },
      { t: "h", x: "Rename an account" },
      { t: "p", x: "Click **⋯** next to an account (or right-click it) and choose **Rename…**. The name is stored for that account id and shown in the menu, the notch, the dashboard, widgets, history and notifications. Leave it blank and save to go back to the email, then the folder name." },
      { t: "h", x: "Hide, show or remove an account" },
      { t: "ul", x: [
        "**Hide from Refill** skips that account. It is not checked and never alerts. This works for Claude, Codex, Copilot, Gemini and Cursor. Bring one back under **Hidden → Show**. There is no separate mute: hide is how you silence one account.",
        "**Move profile to Trash…** is offered for extra Claude, Codex and Gemini profile folders. It signs that profile out on this Mac and can be undone from the Trash. The default `~/.claude`, `~/.codex` and `~/.gemini` are never offered. Copilot and Cursor have no profile folder to trash.",
      ] },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`Not signed in. Run claude and type /login.`: that profile has no login. Do the Claude steps above.",
        "`Login expired. Run claude once to renew it.`: run Claude Code once in that profile. Or turn on **Settings → Accounts → Renew expired logins** so Refill renews it. Leave it off if Claude Code runs all day.",
        "`Rate limited. Next try at …`: Refill pauses that account after an HTTP 429 and retries by itself.",
        "`No Codex sessions yet`: use that Codex home once. Numbers update only when Codex writes a session log.",
      ] },
    ],
  },
  {
    id: "copilot", title: "GitHub Copilot", group: "Sources",
    intro: "Monthly premium-request and chat quota for every GitHub login that has a Copilot seat.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Install the GitHub CLI and sign in with each account that has Copilot. `gh auth login` adds another login. `gh auth status` lists them.",
        "Refill reads each `github.com` login with `gh auth token --user <login>`. The first login it tracks stays `copilot:default`, so switching the active `gh` user does not reshuffle history. Other logins are `copilot:<login>`.",
        "Check **Settings → Accounts → More providers → GitHub Copilot** is on. Click **Refresh**.",
      ] },
      { t: "code", copy: true, x: "brew install gh" },
      { t: "code", copy: true, x: "gh auth login" },
      { t: "p", x: "If `gh` has no `github.com` login, Refill falls back to the single editor token in `~/.config/github-copilot` (`apps.json` or `hosts.json`) as `copilot:default`. Enterprise hosts are ignored. The Copilot editor itself is one login. Usage resets monthly. The endpoint is unofficial and can change." },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`No GitHub token (run gh auth login)`: sign in with the command above.",
        "`No GitHub token for <login>`: that login has no token. Run `gh auth login` again for it.",
        "`HTTP 401` or `403 (token rejected or no Copilot seat)`: that GitHub account has no Copilot seat. Check with `gh auth status`. Hide the row if you do not want it listed.",
      ] },
    ],
  },
  {
    id: "cursor", title: "Cursor", group: "Sources",
    intro: "Monthly usage for the Cursor plan signed in on this Mac, with no extra login.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Install the Cursor app and sign in to it.",
        "Check **Settings → Accounts → More providers → Cursor** is on. Click **Refresh**.",
      ] },
      { t: "p", x: "Refill reads the sign-in from Cursor's local database, `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`, in read-only mode. It then asks cursor.com for your usage. The billing cycle end is the reset." },
      { t: "p", x: "Cursor stores one login per Mac user. Refill does not invent a second Cursor account. A second person needs their own macOS user, or you switch the login inside Cursor (that replaces the one Refill shows, id `cursor:default`). You can still rename or hide it." },
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
    intro: "Per-model quota for every Gemini CLI login, with Pro and Flash tracked separately.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Install Gemini CLI, run it once and sign in with Google. The default login is `~/.gemini/oauth_creds.json`, and that account stays `gemini:default`.",
        "Check **Settings → Accounts → More providers → Gemini CLI** is on. Click **Refresh**.",
      ] },
      { t: "code", copy: true, x: "npm install -g @google/gemini-cli" },
      { t: "code", copy: true, x: "gemini" },
      { t: "h", x: "Add another Gemini account" },
      { t: "p", x: "Gemini CLI treats `GEMINI_CLI_HOME` as a home directory and writes creds to `$GEMINI_CLI_HOME/.gemini/oauth_creds.json`, not to the home itself." },
      { t: "ol", x: [
        "Under **Add a Gemini account**, type a name such as `work`, then click **Add**.",
        "Terminal opens with `GEMINI_CLI_HOME` set to `~/.gemini-accounts/work`. Sign in, then exit.",
        "Click **Refresh**. The login lives at `~/.gemini-accounts/work/.gemini/oauth_creds.json`.",
      ] },
      { t: "code", copy: true, x: "scripts/add-gemini-account.sh work" },
      { t: "code", copy: true, x: "alias gemini-work='GEMINI_CLI_HOME=$HOME/.gemini-accounts/work gemini'" },
      { t: "p", x: "A folder you already use can be listed under **Extra Gemini folders**. Point it at the directory that contains `oauth_creds.json`, or at a `GEMINI_CLI_HOME` whose `.gemini` child contains that file. `~/.gemini-*` and `~/.gemini_*` folders in your home directory are picked up on their own when they hold creds." },
      { t: "p", x: "When the saved token expires, Refill refreshes it in memory and never writes it back. It needs the installed CLI to find the public OAuth client, or you can set `GEMINI_OAUTH_CLIENT_ID` and `GEMINI_OAUTH_CLIENT_SECRET`. The client is shared. Each account keeps its own token." },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`No Gemini CLI login`: run `gemini` and sign in.",
        "`Gemini token refresh failed (run gemini once)`: run `gemini` once so it renews its own login, then refresh.",
        "`Quota request failed`: Google rejected the request. Try again later.",
      ] },
    ],
  },
];
