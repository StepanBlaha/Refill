"use client";

import { useEffect, useRef, useState } from "react";
import Drip, { type Mood } from "./Drip";
import { DMG, REPO } from "@/lib/site";
import { gsap, motionSafe, ScrollTrigger } from "@/lib/gsap";
import c from "./Shared.module.css";
import s from "./Hero.module.css";

const LINES: Record<string, string[]> = {
  happy: ["Plenty left.", "All clear.", "Tanks are full."],
  sweaty: ["Running low.", "Not much left.", "Close to the bottom."],
  asleep: ["Empty for now.", "Resting until the reset.", "Back at the next refill."],
  party: ["Refilled.", "Fresh tank.", "Back to full."],
};
const tone = (l: number) => (l < 10 ? "var(--danger)" : l < 30 ? "var(--warn)" : "var(--accent)");
const moodFor = (l: number, refilling: boolean): Mood => (refilling ? "party" : l < 10 ? "asleep" : l < 45 ? "sweaty" : "happy");
// [label, window, share of the main level]
const ACCOUNTS = [
  ["work", "5h session", 1],
  ["personal", "Weekly", 0.62],
  ["side-hustle", "Opus", 0.24],
] as const;

export default function Hero() {
  const root = useRef<HTMLElement>(null);
  const panel = useRef<HTMLDivElement>(null);
  const bars = useRef<(HTMLElement | null)[]>([]);
  const nums = useRef<(HTMLElement | null)[]>([]);
  const mbFill = useRef<HTMLElement>(null);
  const mbPct = useRef<HTMLElement>(null);
  const [face, setFace] = useState<{ mood: Mood; pct: number; say: string }>({ mood: "happy", pct: 72, say: "Plenty left." });

  // Bars + Drip loop: drain, sleep, refill, party.
  useEffect(() => {
    const draw = (level: number) => {
      ACCOUNTS.forEach(([, , k], i) => {
        const v = level * k;
        const b = bars.current[i];
        if (b) {
          b.style.transform = `scaleX(${v / 100})`;
          b.style.background = tone(v);
        }
        const n = nums.current[i];
        if (n) n.textContent = `${Math.round(v)}%`;
      });
      if (mbFill.current) {
        mbFill.current.style.width = `${level}%`;
        mbFill.current.style.background = tone(level);
      }
      if (mbPct.current) mbPct.current.textContent = `${Math.round(level)}%`;
    };
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      draw(72);
      return;
    }
    const state = { v: 100, refilling: false };
    let last = "";
    let lastPct = -10;
    const sync = () => {
      const mood = moodFor(state.v, state.refilling);
      const pct = Math.round(state.v);
      draw(state.v);
      if (mood !== last || Math.abs(pct - lastPct) >= 4) {
        const changed = mood !== last;
        last = mood;
        lastPct = pct;
        setFace((f) => ({
          mood,
          pct: state.v,
          say: changed ? LINES[mood][Math.floor(Math.random() * 3)] : f.say,
        }));
      }
    };
    const tl = gsap.timeline({ repeat: -1, onUpdate: sync, delay: 1.2 });
    tl.to(state, { v: 100, duration: 1.4 })
      .to(state, { v: 0, duration: 7, ease: "none" })
      .to(state, { v: 0, duration: 1.6 })
      .call(() => { state.refilling = true; })
      .to(state, { v: 100, duration: 1.4, ease: "power3.out" })
      .to(state, { v: 100, duration: 2.4 })
      .call(() => { state.refilling = false; });
    const io = new IntersectionObserver(([e]) => (e.isIntersecting ? tl.play() : tl.pause()));
    if (panel.current) io.observe(panel.current);
    return () => {
      io.disconnect();
      tl.kill();
    };
  }, []);

  // Entrance + scroll-linked parallax.
  useEffect(
    () =>
      motionSafe(root.current, () => {
        gsap.from(`.${s.line} > span`, { yPercent: 110, duration: 1.1, ease: "expo.out", stagger: 0.12, delay: 0.1 });
        gsap.from(`.${s.fade}`, { opacity: 0, y: 16, duration: 1, ease: "power3.out", stagger: 0.1, delay: 0.5 });
        gsap.from(panel.current, { opacity: 0, y: 48, duration: 1.3, ease: "expo.out", delay: 0.6 });
        gsap.to(panel.current, {
          yPercent: -6,
          scale: 0.98,
          ease: "none",
          scrollTrigger: { trigger: panel.current, start: "top 80%", end: "bottom top", scrub: 0.6 },
        });
        ScrollTrigger.refresh();
      }),
    [],
  );

  return (
    <section className={s.hero} ref={root}>
      <div className={s.copy}>
        <p className={`${c.eyebrow} ${s.fade}`}>macOS menu-bar app</p>
        <h1 className={s.h1}>
          <span className={s.line}><span>Your AI tanks, watched.</span></span>
          <span className={s.line}><span className={s.hl}>Refilled? You&apos;ll know.</span></span>
        </h1>
        <p className={`${c.sub} ${s.lede} ${s.fade}`}>
          Refill keeps an eye on every AI limit you burn through and pings you the second one resets. Lights, phone, Discord, whatever fits. Drip keeps watch.
        </p>
        <div className={`${s.cta} ${s.fade}`}>
          <a className={c.btn} href={DMG}>Download for macOS</a>
          <a className={`${c.btn} ${c.ghost}`} href={REPO}>View on GitHub</a>
        </div>
        <p className={`${c.fine} ${s.fade}`}>macOS 14+ &middot; free &middot; no account</p>
      </div>

      <div className={s.showcase} ref={panel} role="img" aria-label="Refill in the macOS menu bar, showing usage bars for three accounts draining and refilling while Drip changes mood">
        <div className={s.menubar} aria-hidden="true">
          <span className={s.apple}>&#63743;</span><b>Finder</b><span className={s.dim}>File</span><span className={s.dim}>Edit</span><span className={s.dim}>View</span>
          <span className={s.spacer} />
          <span className={s.tank}><i ref={mbFill} /></span>
          <span ref={mbPct} className={s.pct}>72%</span>
          <span className={s.dim}>Wi-Fi</span><span>Tue 9:41</span>
        </div>
        <div className={s.popover} aria-hidden="true">
          <div className={s.phead}>
            <Drip mood={face.mood} pct={face.pct} size={72} />
            <div>
              <b>Refill</b>
              <span className={s.say}>{face.say}</span>
            </div>
          </div>
          {ACCOUNTS.map(([name, win], i) => (
            <div className={s.acct} key={name}>
              <div className={s.arow}><span>{name}</span><em>{win}</em><b ref={(el) => { nums.current[i] = el; }}>72%</b></div>
              <div className={s.track}><i ref={(el) => { bars.current[i] = el; }} /></div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
