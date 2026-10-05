"use client";

import { useRef } from "react";
import { useReveal } from "@/lib/motion";
import c from "./Shared.module.css";
import s from "./Integrations.module.css";

type Chip = { name: string; sends: React.ReactNode };
type Group = { id: string; label: string; wide?: boolean; chips: Chip[] };

const GROUPS: Group[] = [
  {
    id: "phone",
    label: "Phone",
    chips: [
      { name: "ntfy", sends: "A push to your phone on reset, warning or empty." },
      { name: "Pushover", sends: "A push to your phone on reset, warning or empty." },
      { name: "Telegram", sends: "A message from your bot on reset, warning or empty." },
    ],
  },
  {
    id: "chat",
    label: "Chat",
    chips: [
      { name: "Discord", sends: "A message in your channel when a tank changes." },
      { name: "Slack", sends: "A message in your channel when a tank changes." },
    ],
  },
  {
    id: "lights",
    label: "Lights",
    chips: [
      { name: "Home Assistant", sends: "Green for refilled, orange for warming, red for dry." },
      { name: "Hue", sends: "Green for refilled, orange for warming, red for dry." },
      { name: "WLED", sends: "Green for refilled, orange for warming, red for dry." },
    ],
  },
  {
    id: "anything",
    label: "Anything",
    wide: true,
    chips: [
      {
        name: "Webhook",
        sends: (
          <>
            Any URL, custom headers, templates with <code>{"{{title}}"}</code> <code>{"{{color}}"}</code>{" "}
            <code>{"{{json}}"}</code>.
          </>
        ),
      },
      { name: "Shell hook", sends: <>Runs <code>~/.config/refill/on-reset</code> with the event JSON on stdin.</> },
      { name: "Shortcuts", sends: "Fires a Shortcut, or listen for the distributed notification." },
      { name: "Widgets", sends: "macOS widgets for the tanks, plus a local dashboard. Turn on Wi-Fi sharing for your phone." },
    ],
  },
];

const WORDS = [
  "Claude", "Codex", "Copilot", "Cursor", "Gemini", "ntfy", "Pushover", "Telegram", "Discord", "Slack",
  "Home Assistant", "Hue", "WLED", "Webhook", "Shell hook", "Shortcuts", "Widgets",
];

export default function Integrations() {
  const root = useRef<HTMLElement>(null);
  useReveal(root, `.${s.group}`);

  return (
    <section className={c.sec} id="wire" ref={root}>
      <div className={c.wrap}>
        <p className={c.eyebrow}>Integrations</p>
        <h2 className={c.h2}>Wire it to anything.</h2>
        <p className={c.sub}>
          Each integration has its own Test button and per-event toggles. Reset, warning, empty: pick who hears what.
        </p>
        <div className={s.grid}>
          {GROUPS.map((g) => (
            <section className={`${s.group} ${g.wide ? s.wide : ""}`} key={g.id} aria-labelledby={`g-${g.id}`}>
              <h3 id={`g-${g.id}`}>{g.label}</h3>
              <ul className={s.chips}>
                {g.chips.map((ch) => (
                  <li className={s.chip} key={ch.name} tabIndex={0}>
                    <b>{ch.name}</b>
                    <span className={s.sends}>{ch.sends}</span>
                  </li>
                ))}
              </ul>
              {g.id === "lights" && (
                <div className={s.dots} aria-hidden="true"><i /><i /><i /></div>
              )}
            </section>
          ))}
        </div>
      </div>
      <div className={s.marquee} aria-hidden="true">
        <div className={s.track}>
          {[0, 1].map((copy) => (
            <ul className={`${s.words} ${copy ? s.dupe : ""}`} key={copy}>
              {WORDS.map((w) => (
                <li key={w}>{w}</li>
              ))}
            </ul>
          ))}
        </div>
      </div>
    </section>
  );
}
