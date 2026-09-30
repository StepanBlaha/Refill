"use client";

import { useRef } from "react";
import { useStagger } from "@/lib/useStagger";
import { ISSUES, REPO } from "@/lib/site";
import c from "./Shared.module.css";
import s from "./Faq.module.css";

export default function Faq() {
  const root = useRef<HTMLElement>(null);
  useStagger(root, `.${s.item}`);

  return (
    <section className={c.sec} id="faq" ref={root}>
      <div className={c.narrow}>
        <p className={c.eyebrow}>FAQ</p>
        <h2 className={c.h2}>Questions, answered short.</h2>
        <div className={s.list}>
          <details className={s.item}>
            <summary>Does it work offline?</summary>
            <p>Partly. A known reset time is tracked locally, so a scheduled reset still fires. Fresh usage numbers need the provider&apos;s API.</p>
          </details>
          <details className={s.item}>
            <summary>Will it get my account banned?</summary>
            <p>Refill reads usage endpoints that are undocumented and may change or be restricted, the same ones your own tools use, with your own login, at a polite pace. It doesn&apos;t send prompts or spend your quota.</p>
          </details>
          <details className={s.item}>
            <summary>Which macOS versions?</summary>
            <p>macOS 14 Sonoma and newer.</p>
          </details>
          <details className={s.item}>
            <summary>Is it free?</summary>
            <p>Yes. It costs nothing to use. It is open source under the MIT License. The code is on <a href={REPO}>GitHub</a>.</p>
          </details>
          <details className={s.item}>
            <summary>Is it affiliated with Anthropic, OpenAI, GitHub, Cursor or Google?</summary>
            <p>No. It&apos;s an independent tool. Those names belong to their owners.</p>
          </details>
          <details className={s.item}>
            <summary>Why a tank?</summary>
            <p>A battery icon with a little personality. Drip is a small glass tank, so you can see what is left.</p>
          </details>
          <details className={s.item}>
            <summary>Found a bug or want a feature?</summary>
            <p>Open an issue on <a href={ISSUES}>GitHub Issues</a>. That is the only support channel.</p>
          </details>
        </div>
      </div>
    </section>
  );
}
