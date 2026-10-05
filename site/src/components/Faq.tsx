"use client";

import { useRef, useState } from "react";
import { useReveal } from "@/lib/motion";
import { ISSUES, REPO } from "@/lib/site";
import c from "./Shared.module.css";
import s from "./Faq.module.css";

const ITEMS: [string, React.ReactNode][] = [
  ["Does it work offline?", "Partly. A known reset time is tracked locally, so a scheduled reset still fires. Fresh usage numbers need the provider's API."],
  ["Will it ping me at night?", "Quiet hours mute the sound between the times you set. Lights and the shell hook still fire. Phone and chat pushes stay on unless you mute those too."],
  ["Will it get my account banned?", "Refill reads usage endpoints that are undocumented and may change or be restricted, the same ones your own tools use, with your own login, at a polite pace. It doesn't send prompts or spend your quota."],
  ["Which macOS versions?", "macOS 14 Sonoma and newer."],
  ["Is it free?", <>Yes. It costs nothing to use. It is open source under the MIT License. The code is on <a href={REPO}>GitHub</a>.</>],
  ["Is it affiliated with Anthropic, OpenAI, GitHub, Cursor or Google?", "No. It's an independent tool. Those names belong to their owners."],
  ["Why a tank?", "A battery icon with a little personality. Drip is a small glass tank, so you can see what is left."],
  ["Found a bug or want a feature?", <>Open an issue on <a href={ISSUES}>GitHub Issues</a>. That is the only support channel.</>],
];

export default function Faq() {
  const root = useRef<HTMLElement>(null);
  const [open, setOpen] = useState<number | null>(0);
  useReveal(root, `.${s.rv}`);

  return (
    <section className={c.sec} id="faq" ref={root}>
      <div className={`${c.wrap} ${s.layout}`}>
        <div className={s.side}>
          <p className={`${c.eyebrow} ${s.rv}`}>FAQ</p>
          <h2 className={`${c.h2} ${s.rv}`}>Questions, answered short.</h2>
        </div>
        <div className={`${s.list} ${s.rv}`}>
          {ITEMS.map(([q, a], i) => {
            const on = open === i;
            return (
              <div className={s.item} data-open={on} key={q}>
                <h3>
                  <button
                    type="button"
                    className={s.q}
                    aria-expanded={on}
                    aria-controls={`faq-a-${i}`}
                    id={`faq-q-${i}`}
                    onClick={() => setOpen(on ? null : i)}
                  >
                    <span>{q}</span>
                    <span className={s.icon} aria-hidden="true"><i /><i /></span>
                  </button>
                </h3>
                <div className={s.panel} id={`faq-a-${i}`} role="region" aria-labelledby={`faq-q-${i}`}>
                  <div className={s.clip}>
                    <p>{a}</p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
