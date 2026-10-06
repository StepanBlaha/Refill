"use client";

import { useRef } from "react";
import LiveBar from "./LiveBar";
import { useReveal } from "@/lib/motion";
import c from "./Shared.module.css";
import s from "./Sources.module.css";

const OTHERS = [
  ["Codex", "Live usage from the ChatGPT login already in each Codex home. An old session log is only a fallback.", [18, 64], 5.5],
  ["GitHub Copilot", "Premium requests and chat quota, read with your GitHub CLI login. Resets monthly.", [38, 86], 6.5],
  ["Cursor", "Monthly usage from the Cursor app you already have signed in.", [52, 92], 5],
  ["Gemini CLI", "Per-model quota for your Gemini CLI login, Pro and Flash tracked separately.", [26, 74], 7],
] as const;

export default function Sources() {
  const root = useRef<HTMLElement>(null);
  useReveal(root, `.${s.tile}`);

  return (
    <section className={c.sec} id="tank" ref={root}>
      <div className={c.wrap}>
        <div className={s.head}>
          <div>
            <p className={c.eyebrow}>Sources</p>
            <h2 className={c.h2}>Every AI, one tank.</h2>
          </div>
          <p className={`${c.sub} ${s.headSub}`}>
            No more tab-hopping to see who is dry. Each source gets its own gauge in the menu bar.
          </p>
        </div>
        <div className={s.bento}>
          <article className={`${s.tile} ${s.claude}`}>
            <h3>Claude <span className={s.tag}>multi-account</span></h3>
            <p>
              Reads every Claude Code login on your Mac: the default <code>~/.claude</code>, any <code>~/.claude-*</code>,
              plus dirs you add. 5-hour session, weekly, Opus and Sonnet windows, each with its own tank. Expired
              tokens get refreshed for you.
            </p>
            <div className={s.bars}>
              <LiveBar label="work" rest={82} range={[72, 94]} duration={4.5} />
              <LiveBar label="personal" rest={41} range={[22, 58]} duration={5.5} delay={0.4} />
              <LiveBar label="side-hustle" rest={9} range={[4, 34]} duration={6.5} delay={0.8} />
            </div>
          </article>
          {OTHERS.map(([name, text, range, dur]) => (
            <article className={`${s.tile} ${s.small}`} key={name}>
              <h3>{name}</h3>
              <p>{text}</p>
              <LiveBar tiny rest={Math.round((range[0] + range[1]) / 2)} range={[range[0], range[1]]} duration={dur} />
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
