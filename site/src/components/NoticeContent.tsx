import Link from "next/link";
import s from "@/components/Legal.module.css";

export default function NoticeContent() {
  return (
    <>
      <h1>Third-Party Notices</h1>
      <p className={s.fine}>Last updated 2026-09-30</p>

      <ul>
        <li><b>Non-affiliation.</b> Refill is an independent app. It is not affiliated with, endorsed by, or sponsored by Anthropic, PBC, OpenAI, GitHub, Cursor, Google, Philips/Signify, or Home Assistant/Nabu Casa.</li>
        <li><b>Trademarks.</b> "Claude" and "Anthropic" are trademarks of Anthropic, PBC. "Codex", "ChatGPT" and "OpenAI" are trademarks of OpenAI. "GitHub" is a trademark of GitHub, Inc. "Cursor" is a trademark of Anysphere, Inc. "Google" is a trademark of Google LLC. "Philips Hue" is a trademark of Signify. "Home Assistant" is a trademark of Nabu Casa, Inc. "Telegram", "Discord", "Slack", "Pushover", "ntfy" and "WLED" belong to their respective owners. These names appear only descriptively, to say which services Refill can read from or send signals to.</li>
        <li><b>Undocumented endpoints.</b> To read your Claude usage, Refill calls endpoints on <code>api.anthropic.com</code> and <code>console.anthropic.com</code> that are not part of a public, documented API, and it reads the local login that Claude Code stores. Codex usage is read from local session logs whose format is not documented either. Any of these can change or stop working without notice, and their use may be restricted by the provider's terms. You are responsible for checking that your use complies with your provider's terms.</li>
        <li><b>Apple frameworks and SF Symbols.</b> Refill uses AppKit, SwiftUI, WidgetKit and Security (Keychain). SF Symbols are used under Apple's license, which permits them only in apps running on Apple platforms. They must not be used in the app icon, logos or trademarks.</li>
        <li><b>Open-source packages.</b> None. Refill has no third-party package dependencies.</li>
        <li><b>Name.</b> "Refill" is a provisional name. A trademark search has not yet been completed.</li>
        <li><b>GDPR note.</b> The developer runs no servers for Refill and receives, stores and processes no personal data. Data that Refill reads on your Mac stays under your control, and you are the controller of it. Where you configure an integration, the recipient service becomes a separate controller under its own policy.</li>
      </ul>
    </>
  );
}
