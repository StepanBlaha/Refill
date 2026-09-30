"use client";

import { useRef } from "react";
import { useStagger } from "@/lib/useStagger";
import { gsap } from "@/lib/gsap";
import c from "./Shared.module.css";
import s from "./Sources.module.css";

const OTHERS = [
  ["Codex", "Reads rate limits from your local Codex session logs. Offline, updates when you use it."],
  ["GitHub Copilot", "Premium requests and chat quota, read with your GitHub CLI login. Resets monthly."],
  ["Cursor", "Monthly usage from the Cursor app you already have signed in."],
  ["Gemini CLI", "Per-model quota for your Gemini CLI login, Pro and Flash tracked separately."],
];
const BARS = [
  ["work", 82, "var(--accent)"],
  ["personal", 41, "var(--warn)"],
  ["side-hustle", 9, "var(--danger)"],
] as const;

export default function Sources() {
  const root = useRef<HTMLElement>(null);
  useStagger(root, `.${s.card}`, () => {
    gsap.from(`.${s.bar} i`, {
      scaleX: 0,
      duration: 1.4,
      ease: "power3.out",
      stagger: 0.12,
      delay: 0.3,
      scrollTrigger: { trigger: root.current, start: "top 60%", once: true },
    });
  });

  return (
    <section className={c.sec} id="tank" ref={root}>
      <div className={c.wrap}>
        <p className={c.eyebrow}>Sources</p>
        <h2 className={c.h2}>Every AI, one tank.</h2>
        <p className={c.sub}>No more tab-hopping to see who is dry. Each source gets its own gauge in the menu bar.</p>
        <div className={s.cards}>
          <article className={`${s.card} ${s.wide}`}>
            <h3>Claude <span className={s.tag}>multi-account</span></h3>
            <p>
              Reads every Claude Code login on your Mac: the default <code>~/.claude</code>, any <code>~/.claude-*</code>, plus dirs you add. 5-hour session, weekly, Opus and Sonnet windows, each with its own tank. Expired tokens get refreshed for you.
            </p>
            <div className={s.bars}>
              {BARS.map(([name, w, col]) => (
                <div className={s.bar} key={name}>
                  <span>{name}</span>
                  <i style={{ width: `${w}%`, background: col }} />
                </div>
              ))}
            </div>
          </article>
          {OTHERS.map(([name, text]) => (
            <article className={s.card} key={name}>
              <h3>{name}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
