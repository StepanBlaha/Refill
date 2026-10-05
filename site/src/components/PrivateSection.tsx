"use client";

import { useRef } from "react";
import Link from "next/link";
import { useReveal } from "@/lib/motion";
import Arrow from "./Arrow";
import c from "./Shared.module.css";
import s from "./PrivateSection.module.css";

const ICON = { fill: "none", stroke: "currentColor", strokeWidth: 1.8, strokeLinecap: "round", strokeLinejoin: "round" } as const;

export default function PrivateSection() {
  const root = useRef<HTMLElement>(null);
  useReveal(root, `.${s.rv}`);

  return (
    <section className={`${c.sec} ${c.alt}`} id="private" ref={root}>
      <div className={c.wrap}>
        <p className={`${c.eyebrow} ${s.rv}`}>Private by design</p>
        <h2 className={`${s.statement} ${s.rv}`}>
          Your Mac.<br />Your tanks.<br /><span>Nobody else.</span>
        </h2>
        <div className={s.facts}>
          <div className={`${s.fact} ${s.rv}`}>
            <svg width="32" height="32" viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...ICON}>
              <rect x="3" y="4" width="18" height="12" rx="2" /><path d="M8 20h8M12 16v4" />
            </svg>
            <h3>Everything local</h3>
            <p>Usage, history and settings live on your Mac in <code>~/.config/refill</code>.</p>
          </div>
          <div className={`${s.fact} ${s.rv}`}>
            <svg width="32" height="32" viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...ICON}>
              <circle cx="12" cy="12" r="9" /><path d="M5.6 5.6l12.8 12.8" />
            </svg>
            <h3>No account, no telemetry</h3>
            <p>Nothing to sign up for and no Refill server. No analytics, no crash pings, no &quot;anonymous&quot; stats.</p>
          </div>
          <div className={`${s.fact} ${s.rv}`}>
            <svg width="32" height="32" viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...ICON}>
              <rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V8a4 4 0 018 0v3" />
            </svg>
            <h3>Credentials stay put</h3>
            <p>
              Tokens never leave your Mac. Refill only talks to the providers you use (Anthropic, GitHub, Cursor,
              Google) and the integrations you add yourself. Because those endpoints are undocumented, they can change.
            </p>
          </div>
        </div>
        <p className={`${s.more} ${s.rv}`}>
          <Link className={s.link} href="/privacy/">Read the full privacy policy <Arrow /></Link>
        </p>
      </div>
    </section>
  );
}
