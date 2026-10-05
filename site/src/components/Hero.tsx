"use client";

import { Fragment, useEffect, useRef } from "react";
import HeroScreen from "./HeroScreen";
import Arrow from "./Arrow";
import { DMG, REPO } from "@/lib/site";
import { DUR, EASE, STAGGER, gsap, motionSafe } from "@/lib/motion";
import c from "./Shared.module.css";
import s from "./Hero.module.css";

const LINES = [
  { words: ["Your", "AI", "tanks,", "watched."], hl: false },
  { words: ["Refilled?", "You'll", "know."], hl: true },
];

export default function Hero() {
  const root = useRef<HTMLElement>(null);

  // Per-word masked reveal, then the supporting copy and the screen.
  useEffect(
    () =>
      motionSafe(root.current, () => {
        gsap.from(`.${s.w} > span`, { yPercent: 115, duration: 1.1, ease: EASE.expo, stagger: STAGGER * 1.5, delay: 0.1 });
        gsap.from(`.${s.fade}`, { opacity: 0, y: 16, duration: DUR.l, ease: EASE.out, stagger: 0.1, delay: 0.55 });
        gsap.from(`.${s.rise}`, { opacity: 0, y: 48, duration: 1.3, ease: EASE.expo, delay: 0.75 });
      }),
    [],
  );

  return (
    <section className={s.hero} ref={root}>
      <div className={s.copy}>
        <p className={`${c.eyebrow} ${s.fade}`}>macOS menu-bar app</p>
        <h1 className={s.h1}>
          {LINES.map((l) => (
            <span className={`${s.line} ${l.hl ? s.hl : ""}`} key={l.words[0]}>
              {l.words.map((w) => (
                <Fragment key={w}>
                  <span className={s.w}><span>{w}</span></span>{" "}
                </Fragment>
              ))}
            </span>
          ))}
        </h1>
        <p className={`${c.sub} ${s.lede} ${s.fade}`}>
          Refill watches every AI limit you burn through and pings you the second one resets. Lights, phone, Discord,
          whatever fits. Drip keeps watch.
        </p>
        <div className={`${s.cta} ${s.fade}`}>
          <a className={c.btn} href={DMG}>Download for macOS <Arrow /></a>
          <a className={`${c.btn} ${c.ghost}`} href={REPO}>View on GitHub <Arrow /></a>
        </div>
        <p className={`${c.fine} ${s.fade}`}>macOS 14+ &middot; free &middot; no account</p>
      </div>
      <div className={s.rise}>
        <HeroScreen />
      </div>
    </section>
  );
}
