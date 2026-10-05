"use client";

import { useEffect, useRef } from "react";
import { gsap, motionSafe } from "@/lib/motion";
import c from "./Shared.module.css";
import s from "./Burn.module.css";

const FONT = "-apple-system, system-ui, sans-serif";
const PACE = 34;

export default function Burn() {
  const root = useRef<HTMLElement>(null);
  const counter = useRef<HTMLElement>(null);

  // Line draws on scroll (stroke-dashoffset scrub), then the projection, labels and the %/h counter follow.
  useEffect(
    () =>
      motionSafe(root.current, () => {
        const line = root.current?.querySelector<SVGPathElement>("[data-line]");
        const proj = root.current?.querySelector<SVGPathElement>("[data-proj]");
        if (!line || !proj) return;
        const len = line.getTotalLength();
        const plen = proj.getTotalLength();
        gsap.set(line, { strokeDasharray: len, strokeDashoffset: len });
        gsap.set(proj, { strokeDasharray: plen, strokeDashoffset: plen });
        gsap.set(proj, { opacity: 0 });
        gsap.set("[data-late]", { opacity: 0 });
        gsap.set("[data-area]", { opacity: 0 });
        const n = { v: 0 };
        const paint = () => {
          if (counter.current) counter.current.textContent = String(Math.round(n.v));
        };
        paint();
        gsap
          .timeline({
            defaults: { ease: "none" },
            scrollTrigger: { trigger: `.${s.panel}`, start: "top 75%", end: "bottom 55%", scrub: 0.8 },
          })
          .to(line, { strokeDashoffset: 0, duration: 3 })
          .to("[data-area]", { opacity: 1, duration: 1 }, 1.5)
          .to(n, { v: PACE, duration: 3, onUpdate: paint }, 0)
          .to(proj, { opacity: 1, duration: 0.01 }, 3)
          .to(proj, { strokeDashoffset: 0, duration: 1 }, 3)
          .to("[data-late]", { opacity: 1, duration: 0.6, stagger: 0.3 }, 3.6);
      }),
    [],
  );

  return (
    <section className={c.sec} id="burn" ref={root}>
      <div className={c.wrap}>
        <div className={c.center}>
          <p className={c.eyebrow}>Burn rate</p>
          <h2 className={c.h2}>See how fast you&apos;re drinking it.</h2>
          <p className={c.sub}>
            A little chart per tank shows your pace against the clock, so you know whether the refactor fits before the
            reset. Or whether Drip should start to worry.
          </p>
        </div>
        <figure className={s.panel} aria-label="Sample burn rate chart">
          <div className={s.stats}>
            <div><span>Pace</span><b><em ref={counter}>{PACE}</em>%/h</b></div>
            <div><span>Used</span><b>78%</b></div>
            <div className={s.warnStat}><span>Empty at</span><b>14:32</b></div>
          </div>
          <svg viewBox="0 0 800 340" role="img" aria-label="Usage climbing from 0 to 78 percent over the first 3.75 hours of a 5 hour window, projected to be empty at 14:32, before the reset">
            <g stroke="rgba(255,255,255,.1)" strokeWidth="1"><path d="M60 300H780M60 235H780M60 170H780M60 105H780M60 40H780" /></g>
            <g fill="#808080" fontFamily={FONT} fontSize="18">
              <text x="0" y="305">0%</text><text x="0" y="45">100%</text>
              <text x="60" y="326">0h</text><text x="348" y="326">2h</text><text x="636" y="326">4h</text><text x="780" y="326" textAnchor="end">5h reset</text>
            </g>
            <path d="M60 300L780 40" stroke="#808080" strokeWidth="1.5" strokeDasharray="4 6" fill="none" />
            <path data-area d="M60 300L132 284.4 204 274 276 232.4 348 185.6 420 164.8 492 133.6 600 97.2V300z" fill="rgba(48,209,88,.12)" />
            <path data-line d="M60 300L132 284.4 204 274 276 232.4 348 185.6 420 164.8 492 133.6 600 97.2" stroke="#30D158" strokeWidth="3" fill="none" strokeLinejoin="round" strokeLinecap="round" />
            <path data-proj d="M600 97.2L693 40" stroke="#FF9F0A" strokeWidth="3" strokeDasharray="2 8" strokeLinecap="round" fill="none" />
            <g data-late>
              <circle cx="600" cy="97.2" r="7" fill="#30D158" />
              <text x="586" y="80" textAnchor="end" fill="#30D158" fontFamily={FONT} fontSize="18" fontWeight="600">now 13:52</text>
            </g>
            <g data-late>
              <path d="M693 40V300" stroke="#FF9F0A" strokeWidth="1.5" strokeDasharray="3 5" fill="none" />
              <circle cx="693" cy="40" r="6" fill="#FF9F0A" />
              <text x="540" y="28" fill="#FF9F0A" fontFamily={FONT} fontSize="18" fontWeight="600">empty at 14:32</text>
            </g>
          </svg>
          <figcaption>Dashed grey is an even pace. Amber is where you&apos;re headed.</figcaption>
        </figure>
      </div>
    </section>
  );
}
