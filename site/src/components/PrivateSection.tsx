"use client";

import { useRef } from "react";
import Link from "next/link";
import { useStagger } from "@/lib/useStagger";
import c from "./Shared.module.css";
import s from "./PrivateSection.module.css";

export default function PrivateSection() {
  const root = useRef<HTMLElement>(null);
  useStagger(root, `.${s.item}`);

  return (
    <section className={`${c.sec} ${c.alt}`} id="private" ref={root}>
      <div className={c.wrap}>
        <p className={c.eyebrow}>Private by design</p>
        <h2 className={c.h2}>Your Mac. Your tanks. Nobody else.</h2>
        <div className={s.priv}>
          <div className={s.item}><b>Everything local</b><p>Usage, history and settings live on your Mac in <code>~/.config/refill</code>.</p></div>
          <div className={s.item}><b>No account</b><p>Nothing to sign up for. There is no Refill server.</p></div>
          <div className={s.item}><b>No telemetry</b><p>No analytics, no crash pings, no &quot;anonymous&quot; stats.</p></div>
          <div className={s.item}><b>Credentials stay put</b><p>Tokens never leave your Mac. Refill only talks to the providers you use (Anthropic, GitHub, Cursor, Google) and the integrations you add yourself. Because those endpoints are undocumented, they can change.</p></div>
        </div>
        <p className={s.more}><Link href="/privacy/">Read the full privacy policy</Link></p>
      </div>
    </section>
  );
}
