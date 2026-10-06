import Link from "next/link";
import s from "@/components/Legal.module.css";

export default function PrivacyContent() {
  return (
    <>
      <h1>Privacy Policy</h1>
      <p className={s.fine}>Last updated 2026-10-06</p>

      <p>Refill is a Mac menu-bar app that watches your AI usage limits and signals when they reset. It is built to keep your data on your Mac. The developer collects nothing: there is no Refill server, no account, no analytics and no telemetry.</p>

      <h2>What Refill reads on your Mac</h2>
      <div className={s.tableWrap}><table><thead><tr><th>Data</th><th>Where it comes from</th><th>Why</th></tr></thead><tbody>
        <tr><td>Claude Code login (access and refresh tokens)</td><td>macOS Keychain, items named <code>Claude Code-credentials*</code></td><td>To ask Anthropic for your own usage</td></tr>
        <tr><td>Claude config folders and account email</td><td><code>~/.claude</code>, <code>~/.claude-*</code>, and the <code>.claude.json</code> in each</td><td>To find your accounts and label them</td></tr>
        <tr><td>Codex CLI login (access and refresh tokens, account id)</td><td><code>auth.json</code> in each Codex home (<code>~/.codex</code>, <code>CODEX_HOME</code>, <code>~/.codex-*</code>, <code>~/.codex_*</code> and extra folders you list), or the Keychain item <code>Codex Auth</code> when Codex stored the login there</td><td>To ask OpenAI for that home's usage, and to renew an expired access token</td></tr>
        <tr><td>GitHub Copilot token (optional)</td><td><code>gh auth token</code> for each <code>github.com</code> login, or one editor token in <code>~/.config/github-copilot/</code> when <code>gh</code> is not signed in</td><td>To show Copilot quota</td></tr>
        <tr><td>Cursor login (optional)</td><td>Cursor's local database <code>~/Library/Application Support/Cursor/User/globalStorage/state.vscdb</code>, read-only. One login per Mac user</td><td>To show Cursor usage</td></tr>
        <tr><td>Gemini CLI login (optional)</td><td><code>~/.gemini/oauth_creds.json</code>, <code>$GEMINI_CLI_HOME/.gemini/oauth_creds.json</code>, <code>~/.gemini-*</code>, <code>~/.gemini-accounts/&lt;name&gt;/.gemini</code>, and extra folders you list. A refreshed token is kept in memory only</td><td>To show Gemini quota</td></tr>
      </tbody></table></div>

      <h2>What Refill stores</h2>
      <div className={s.tableWrap}><table><thead><tr><th>Data</th><th>Where it is stored</th><th>Why</th></tr></thead><tbody>
        <tr><td>Usage snapshot, event log, history, state</td><td><code>~/.config/refill/</code> (<code>status.json</code>, <code>events.jsonl</code>, <code>history.jsonl</code>, <code>state.json</code>)</td><td>To show gauges and trends and to notice resets</td></tr>
        <tr><td>Integration settings and tokens</td><td><code>~/.config/refill/integrations.json</code> (permissions 0600)</td><td>To send signals to services you set up. It may hold webhook URLs, bot tokens or API keys</td></tr>
        <tr><td>On-reset hook script (optional)</td><td><code>~/.config/refill/</code></td><td>To run your own script when a limit resets</td></tr>
        <tr><td>Widget data</td><td>App-group container shared with Refill widgets</td><td>To show usage in widgets</td></tr>
        <tr><td>Refreshed Claude login</td><td>Written back to the same Keychain item it was read from</td><td>So Claude Code keeps working after a token refresh</td></tr>
        <tr><td>Refreshed Codex login</td><td>Written back to the same <code>auth.json</code> or Keychain item it was read from (mode 0600 for the file)</td><td>So Codex keeps working after a token refresh</td></tr>
        <tr><td>Codex session logs, only if the live usage request fails</td><td>Newest <code>rollout-*.jsonl</code> under that home's <code>sessions/</code></td><td>A fallback gauge. A window whose reset time has already passed is shown as unknown</td></tr>
        <tr><td>Settings, including a custom name per account</td><td>macOS user defaults (<code>accountLabels</code> and the rest)</td><td>To remember your preferences and the names you chose</td></tr>
        <tr><td>Scheduled ntfy resets</td><td><code>~/.config/refill/ntfy-schedule.json</code> (permissions 0600). Account id, window, display name, reset time, server and topic. No token</td><td>To replace or cancel a push Refill already asked ntfy to deliver</td></tr>
      </tbody></table></div>

      <h2>Where your data goes</h2>
      <ul>
        <li><b>OpenAI.</b> <code>chatgpt.com</code> receives the Codex access token and returns usage (<code>/backend-api/wham/usage</code>). <code>auth.openai.com</code> receives the refresh token only when that access token is expired or rejected. This is under <a href="https://openai.com/policies/privacy-policy">OpenAI's privacy policy</a>.</li>
        <li><b>Anthropic.</b> <code>api.anthropic.com</code> receives your access token and returns your usage. <code>console.anthropic.com</code> receives your refresh token when the access token has expired. This is under <a href="https://www.anthropic.com/legal/privacy">Anthropic's privacy policy</a>.</li>
        <li><b>GitHub.</b> <code>api.github.com</code> receives your GitHub token and returns your Copilot quota (<a href="https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement">GitHub's privacy statement</a>).</li>
        <li><b>Cursor.</b> <code>cursor.com</code> receives your Cursor session and returns your usage (<a href="https://cursor.com/privacy">Cursor's privacy policy</a>).</li>
        <li><b>Google.</b> <code>oauth2.googleapis.com</code> (token refresh) and <code>cloudcode-pa.googleapis.com</code> (quota) receive your Gemini CLI login (<a href="https://policies.google.com/privacy">Google's privacy policy</a>).</li>
        <li><b>Integrations you configure.</b> Only if you set them up: ntfy, Pushover, Telegram, Discord, Slack, Home Assistant, Philips Hue, WLED and custom webhooks. They receive the event text and color you configured, at the address you chose, and nothing more. When ntfy is on, Refill may also send a delayed message ahead of a reset (the account's display name, the window name and the delivery time). The ntfy token stays on the Mac. Their handling of that data is governed by their own policies.</li>
        <li><b>Nothing else.</b> No developer server, no analytics, no crash reporting, no advertising, no cookies. Credentials are never sent anywhere except the service they belong to. Codex session logs stay on the Mac. This website sets no cookies either.</li>
      </ul>

      <h2>Local dashboard and iPhone companion</h2>
      <p>Refill can serve a read-only dashboard on port 7788. It is off by default. When you turn on network access, <b>anyone on your local network can see your usage</b> while it is on. It never goes to the internet. The iPhone companion talks only to your Mac on the local network.</p>

      <h2>Optional shell hook</h2>
      <p>If you choose to set an on-reset hook, Refill runs your own script when a limit resets. What that script does is your responsibility.</p>

      <h2>Your control</h2>
      <ul>
        <li><b>Remove an integration</b> in Settings, or delete <code>integrations.json</code>.</li>
        <li><b>Turn off the dashboard</b> in Settings.</li>
        <li><b>Delete all local data:</b> quit Refill and delete <code>~/.config/refill/</code>. Refill never removes Claude Code's own Keychain login.</li>
        <li>Uninstalling the app ends everything it does.</li>
      </ul>

      <h2>Data protection (GDPR)</h2>
      <p>The developer processes no personal data, so there is no controller relationship with the developer. You are the controller of the data on your Mac. Recipients of integrations are separate controllers under their own policies.</p>

      <h2>Children</h2>
      <p>Refill is not directed at children under 13 (16 in the EU).</p>

      <h2>Changes</h2>
      <p>Updates to this policy will be dated above and shipped with the app.</p>

      <h2>Contact</h2>
      <p>Stepan Blaha, Czech Republic: <a href="https://github.com/StepanBlaha/Refill/issues">GitHub Issues</a></p>
    </>
  );
}
