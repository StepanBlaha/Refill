import { BASE, DISCLAIMER, DMG, REPO, SITE_URL } from "@/lib/site";
import s from "./Legal.module.css";
import p from "./Press.module.css";

const RAW = "https://github.com/StepanBlaha/Refill/raw/main/branding";

const COLORS: { name: string; hex: string; note: string }[] = [
  { name: "Ink", hex: "#000000", note: "Window and menu surface" },
  { name: "Panel", hex: "#1C1C1E", note: "Raised panels" },
  { name: "Raised", hex: "#2C2C2E", note: "Rows and fields" },
  { name: "Text", hex: "#FFFFFF", note: "Primary type" },
  { name: "Muted", hex: "#808080", note: "Secondary type" },
  { name: "Green", hex: "#30D158", note: "Accent, tank is fine" },
  { name: "Amber", hex: "#FF9F0A", note: "Warning" },
  { name: "Red", hex: "#FF453A", note: "Empty or danger" },
];

export default function PressContent() {
  return (
    <>
      <h1>Press kit</h1>
      <p className={s.fine}>Name, Drip, colors and a boilerplate.</p>
      <p>
        Everything you need to write about Refill. Questions go to{" "}
        <a href={`${REPO}/issues`}>GitHub Issues</a>.
      </p>

      <img className={p.mark} src={`${BASE}/icon-192.png`} width={96} height={96} alt="Refill app icon" />

      <h2>Name</h2>
      <ul>
        <li>
          Write <b>Refill</b>, with a capital R. Not &quot;REFILL&quot;, &quot;refill app&quot; or &quot;Refill for Claude&quot;.
        </li>
        <li>
          <b>Drip</b> is the mascot: a flat tank with a face. The liquid is how much of the limit is left.
        </li>
        <li>
          Don&apos;t put Claude, Codex, Copilot, Cursor or Gemini in the product name or on the icon. &quot;Works with
          Claude Code and Codex&quot; is fine, under the Refill name.
        </li>
        <li>{DISCLAIMER}</li>
        <li>
          The source is MIT. The Refill name, Drip and the app icon are not. See the{" "}
          <a href={`${REPO}/blob/main/TRADEMARKS.md`}>trademark note</a>.
        </li>
      </ul>

      <h2>Boilerplate</h2>
      <p>
        <b>Short.</b> Refill is a free, open-source macOS menu-bar app that watches your Claude, Codex, Copilot, Cursor
        and Gemini usage limits and signals the moment they reset.
      </p>
      <p>
        <b>Long.</b> Refill lives in the menu bar and shows how much of each limit is left. When a window refills, Drip
        says so: a notch banner, a notification, a sound, and any phone, chat, light or webhook you&apos;ve set up. It
        also warns as you cross the thresholds you set, and when a tank hits empty. There is no Refill account, no
        telemetry and no Refill server. Usage stays in <code>~/.config/refill</code> on your Mac. It requires macOS 14
        or later, and it isn&apos;t notarized, so the first launch needs Open Anyway in Privacy &amp; Security.
      </p>

      <h2>Downloads</h2>
      <ul className={p.downloads}>
        <li>
          <a href={`${RAW}/icon-1024.png`}>App icon, 1024×1024 PNG</a>
        </li>
        <li>
          <a href={`${RAW}/AppIcon.icns`}>App icon, ICNS</a>
        </li>
        <li>
          <a href={`${RAW}/og-1200x630.png`}>Social card, 1200×630 PNG</a>
        </li>
        <li>
          <a href={DMG}>Refill.dmg</a>, the latest release
        </li>
      </ul>
      <figure className={p.card}>
        <img src={`${BASE}/og.png`} width={1200} height={630} alt="Refill social card: Drip and usage for Claude and Codex" />
      </figure>

      <h2>Colors</h2>
      <p>Black surface, white type, one green accent. Amber and red are status, not decoration.</p>
      <ul className={p.swatches}>
        {COLORS.map((c) => (
          <li key={c.hex}>
            <div className={p.chip} style={{ background: c.hex }} />
            <div className={p.meta}>
              <b>{c.name}</b>
              {c.hex}
              <br />
              {c.note}
            </div>
          </li>
        ))}
      </ul>

      <h2>Facts</h2>
      <div className={s.tableWrap}>
        <table>
          <tbody>
            <tr>
              <th>Price</th>
              <td>Free</td>
            </tr>
            <tr>
              <th>License</th>
              <td>MIT for the source. The name, Drip and the icon are not included.</td>
            </tr>
            <tr>
              <th>System</th>
              <td>macOS 14 Sonoma or later</td>
            </tr>
            <tr>
              <th>Developer</th>
              <td>Stepan Blaha</td>
            </tr>
            <tr>
              <th>Website</th>
              <td>
                <a href={SITE_URL}>{SITE_URL}</a>
              </td>
            </tr>
            <tr>
              <th>Source</th>
              <td>
                <a href={REPO}>{REPO}</a>
              </td>
            </tr>
            <tr>
              <th>Bundle ID</th>
              <td>
                <code>cz.stepanblaha.refill</code>
              </td>
            </tr>
            <tr>
              <th>Notarization</th>
              <td>Not notarized. First launch needs Open Anyway.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </>
  );
}
