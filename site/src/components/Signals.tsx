"use client";

import { useEffect, useRef } from "react";
import Drip from "./Drip";
import { gsap, motionSafe, ScrollTrigger } from "@/lib/gsap";
import c from "./Shared.module.css";
import s from "./Signals.module.css";

const TICKS = [
  ["Notch pop-up.", "Drip slides down from the top of your screen."],
  ["Native notification.", "Short, plain words from Drip."],
  ["Sound.", "A chime you can actually tell apart from Slack."],
  ["Warnings too.", "Nudges at 80% and 95%, and a dry-tank alert at 100%."],
];

export default function Signals() {
  const root = useRef<HTMLElement>(null);
  const scene = useRef<HTMLDivElement>(null);

  // Scroll-scrubbed: the notch expands, Drip peeks out, then the toast and notifications arrive.
  useEffect(
    () =>
      motionSafe(root.current, () => {
        const q = (n: string) => `.${s[n]}`;
        const desktop = window.innerWidth >= 900;
        const tl = gsap.timeline({
          defaults: { ease: "power2.inOut" },
          scrollTrigger: {
            trigger: desktop ? root.current : scene.current,
            start: desktop ? "top top+=56" : "top 75%",
            end: desktop ? "+=110%" : "bottom 55%",
            scrub: 0.7,
            pin: desktop ? true : false,
            anticipatePin: 1,
          },
        });
        tl.from(q("notch"), { width: 128, height: 30, duration: 1 })
          .from(q("peek"), { yPercent: 120, opacity: 0, duration: 0.8 }, 0.5)
          .from(q("toast"), { opacity: 0, x: -8, duration: 0.6 }, 0.8)
          .from(q("notif"), { opacity: 0, y: 28, stagger: 0.45, duration: 0.7 }, 1.4)
          .to({}, { duration: 0.4 });
        ScrollTrigger.refresh();
      }),
    [],
  );

  return (
    <section className={`${c.sec} ${c.alt}`} id="signals" ref={root}>
      <div className={`${c.wrap} ${c.split}`}>
        <div>
          <p className={c.eyebrow}>Signals</p>
          <h2 className={c.h2}>Know the second it refills.</h2>
          <p className={c.sub}>
            A limit resets. Refill notices, even if you were offline when it happened. Then it gets loud, in whatever way you like.
          </p>
          <ul className={s.ticks}>
            {TICKS.map(([b, t]) => (
              <li key={b}><b>{b}</b> {t}</li>
            ))}
          </ul>
        </div>
        <div className={s.scene} ref={scene} aria-hidden="true">
          <div className={s.notch}>
            <span className={s.peek}><Drip mood="party" size={44} /></span>
            <div className={s.toast}>
              <b>Tank&apos;s full</b>
              <span>work-claude@very-long-company.example: the 5h session is fresh. Whatever you were doing, resume it.</span>
            </div>
          </div>
          <div className={s.notifs}>
            <div className={s.notif}>
              <Drip mood="sweaty" pct={18} size={44} />
              <div><b>Running warm</b><span>personal at 82%. Refill in 1h 12m.</span></div>
            </div>
            <div className={s.notif}>
              <Drip mood="asleep" pct={0} size={44} />
              <div><b>Tank&apos;s dry</b><span>side-hustle hit the limit. Back at the next reset.</span></div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
