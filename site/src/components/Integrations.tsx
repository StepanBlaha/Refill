"use client";

import { useRef } from "react";
import { useStagger } from "@/lib/useStagger";
import c from "./Shared.module.css";
import s from "./Integrations.module.css";

export default function Integrations() {
  const root = useRef<HTMLElement>(null);
  useStagger(root, `.${s.tile}`);

  return (
    <section className={c.sec} id="wire" ref={root}>
      <div className={c.wrap}>
        <p className={c.eyebrow}>Integrations</p>
        <h2 className={c.h2}>Wire it to anything.</h2>
        <p className={c.sub}>
          Each integration has its own Test button and per-event toggles. Reset, warning, empty: pick who hears what.
        </p>
        <div className={s.grid}>
          <div className={s.tile}><h3>Phone push</h3><p>ntfy, Pushover, Telegram</p></div>
          <div className={s.tile}><h3>Chat</h3><p>Discord, Slack</p></div>
          <div className={s.tile}>
            <h3>Room lights</h3>
            <p>Home Assistant, Hue, WLED. Green for refilled, orange for warming, red for dry.</p>
            <div className={s.dots} aria-hidden="true"><i /><i /><i /></div>
          </div>
          <div className={s.tile}>
            <h3>Webhook</h3>
            <p>Any URL, custom headers, body templates with <code>{"{{title}}"}</code> <code>{"{{color}}"}</code> <code>{"{{json}}"}</code></p>
          </div>
          <div className={s.tile}>
            <h3>Shell hook</h3>
            <p>Drop a script at <code>~/.config/refill/on-reset</code>. Event JSON on stdin.</p>
          </div>
          <div className={s.tile}><h3>Shortcuts</h3><p>Fire a Shortcut, or listen for the distributed notification.</p></div>
          <div className={s.tile}><h3>Widgets</h3><p>macOS widgets for the tanks, plus a local dashboard. Turn on Wi-Fi sharing when you want it on your phone.</p></div>
        </div>
      </div>
    </section>
  );
}
