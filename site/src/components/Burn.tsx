"use client";

import { useEffect, useRef } from "react";
import { gsap, motionSafe } from "@/lib/gsap";
import c from "./Shared.module.css";
import s from "./Burn.module.css";

const FONT = "-apple-system, system-ui, sans-serif";

export default function Burn() {
  const root = useRef<HTMLElement>(null);

  // Line draws on scroll (stroke-dashoffset), then the projection and labels follow.
  useEffect(
    () =>
      motionSafe(root.current, () => {
        const line = root.current?.querySelector<SVGPathElement>("[data-line]");
        if (!line) return;
        const len = line.getTotalLength();
        gsap.set(line, { strokeDasharray: len, strokeDashoffset: len });
        gsap.set("[data-late]", { opacity: 0 });
        gsap.set("[data-area]", { opacity: 0 });
        gsap
          .timeline({
            defaults: { ease: "none" },
            scrollTrigger: { trigger: root.current, start: "top 65%", end: "bottom 60%", scrub: 0.8 },
          })
          .to(line, { strokeDashoffset: 0, duration: 3 })
          .to("[data-area]", { opacity: 1, duration: 1 }, 1.5)
          .to("[data-late]", { opacity: 1, duration: 1, stagger: 0.3 });
      }),
    [],
  );

  return (
    <section className={c.sec} id="burn" ref={root}>
      <div className={`${c.wrap} ${c.split}`}>
        <div>
          <p className={c.eyebrow}>Burn rate</p>
          <h2 className={c.h2}>See how fast you&apos;re drinking it.</h2>
          <p className={c.sub}>
            A little chart per tank shows your pace against the clock, so you know whether the refactor fits before the reset. Or whether Drip should start to worry.
          </p>
        </div>
        <figure className={s.burn} aria-label="Sample burn rate chart">
          <svg viewBox="0 0 400 200" role="img" aria-label="Usage climbing from 0 to 78 percent over five hours, projected to hit the limit before reset">
            <g stroke="rgba(255,255,255,.1)" strokeWidth="1"><path d="M30 20H390M30 70H390M30 120H390M30 170H390" /></g>
            <path d="M30 170L390 20" stroke="#808080" strokeWidth="1.5" strokeDasharray="4 5" fill="none" />
            <path data-area d="M30 170L90 158 150 150 210 112 270 84 300 72V170z" fill="rgba(48,209,88,.12)" />
            <path data-line d="M30 170L90 158 150 150 210 112 270 84 300 72" stroke="#30D158" strokeWidth="2" fill="none" strokeLinejoin="round" strokeLinecap="round" />
            <g data-late>
              <path d="M300 72L370 8" stroke="#FF9F0A" strokeWidth="2.5" strokeDasharray="2 6" strokeLinecap="round" fill="none" />
              <text x="256" y="22" fill="#FF9F0A" fontFamily={FONT} fontSize="11">dry in ~40m</text>
            </g>
            <g data-late>
              <circle cx="300" cy="72" r="5" fill="#30D158" />
              <text x="306" y="98" fill="#30D158" fontFamily={FONT} fontSize="12">now &middot; 78%</text>
            </g>
            <text x="30" y="192" fill="#808080" fontFamily={FONT} fontSize="11">0h</text>
            <text x="352" y="192" fill="#808080" fontFamily={FONT} fontSize="11">5h reset</text>
          </svg>
          <figcaption>Dashed grey is an even pace. Amber is where you&apos;re headed.</figcaption>
        </figure>
      </div>
    </section>
  );
}
