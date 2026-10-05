"use client";

import { useEffect, useRef, useState } from "react";
import Drip, { type Mood } from "./Drip";
import { DUR, EASE, gsap, isFinePointer, motionSafe, prefersReducedMotion } from "@/lib/motion";
import s from "./HeroScreen.module.css";

const LINES: Record<string, string[]> = {
  happy: ["Plenty left.", "All clear.", "Tanks are full."],
  sweaty: ["Running low.", "Not much left.", "Close to the bottom."],
  asleep: ["Empty for now.", "Resting until the reset.", "Back at the next refill."],
  party: ["Refilled.", "Fresh tank.", "Back to full."],
};
const tone = (l: number) => (l < 10 ? "var(--danger)" : l < 30 ? "var(--warn)" : "var(--accent)");
const moodFor = (l: number, refilling: boolean): Mood => (refilling ? "party" : l < 10 ? "asleep" : l < 45 ? "sweaty" : "happy");
const mmss = (t: number) => `${String(Math.floor(t / 60)).padStart(2, "0")}:${String(t % 60).padStart(2, "0")}`;

// [label, window, share of the main level, countdown start in seconds]
const ACCOUNTS = [
  ["work", "5h session", 1, 42 * 60 + 18],
  ["personal", "Weekly", 0.62, 17 * 60 + 5],
  ["side-hustle", "Opus", 0.24, 3 * 60 + 41],
] as const;

export default function HeroScreen() {
  const stage = useRef<HTMLDivElement>(null);
  const tilt = useRef<HTMLDivElement>(null);
  const bars = useRef<(HTMLElement | null)[]>([]);
  const nums = useRef<(HTMLElement | null)[]>([]);
  const clocks = useRef<(HTMLElement | null)[]>([]);
  const mbFill = useRef<HTMLElement>(null);
  const mbPct = useRef<HTMLElement>(null);
  const shape = useRef<HTMLDivElement>(null);
  const toast = useRef<HTMLDivElement>(null);
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
        mbFill.current.style.transform = `scaleX(${level / 100})`;
        mbFill.current.style.background = tone(level);
      }
      if (mbPct.current) mbPct.current.textContent = `${Math.round(level)}%`;
    };
    const paintClocks = (left: number[]) => {
      left.forEach((t, i) => {
        const el = clocks.current[i];
        if (el) el.textContent = mmss(t);
      });
      const el = clocks.current[3];
      if (el) el.textContent = mmss(left[0]);
    };
    const left: number[] = ACCOUNTS.map((a) => a[3]);
    paintClocks(left);
    if (prefersReducedMotion()) {
      draw(72);
      return;
    }
    const tick = window.setInterval(() => {
      if (document.hidden) return;
      ACCOUNTS.forEach((a, i) => {
        left[i] = left[i] <= 1 ? a[3] : left[i] - 1;
      });
      paintClocks(left);
    }, 1000);

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
        setFace((f) => ({ mood, pct: state.v, say: changed ? LINES[mood][Math.floor(Math.random() * 3)] : f.say }));
      }
    };
    const tl = gsap.timeline({ repeat: -1, onUpdate: sync, delay: 1.2 });
    tl.to(state, { v: 100, duration: 1.4 })
      .to(state, { v: 0, duration: 8, ease: "none" })
      .to(state, { v: 0, duration: 1.8 })
      .call(() => { state.refilling = true; })
      .to(state, { v: 100, duration: 1.4, ease: "power3.out" })
      .to(state, { v: 100, duration: 2.6 })
      .call(() => { state.refilling = false; });
    const io = new IntersectionObserver(([e]) => (e.isIntersecting ? tl.play() : tl.pause()));
    if (stage.current) io.observe(stage.current);
    return () => {
      window.clearInterval(tick);
      io.disconnect();
      tl.kill();
    };
  }, []);

  // Notch expands once on load with a "Tank's full" toast, then tucks back.
  useEffect(
    () =>
      motionSafe(stage.current, () => {
        gsap.set(shape.current, { scaleX: 0.42, scaleY: 0.4, transformOrigin: "50% 0%" });
        gsap.set(toast.current, { opacity: 0 });
        gsap
          .timeline({ delay: 1.6, defaults: { ease: EASE.expo } })
          .to(shape.current, { scaleX: 1, scaleY: 1, duration: DUR.m })
          .to(toast.current, { opacity: 1, duration: DUR.s, ease: EASE.out }, "-=0.45")
          .to(toast.current, { opacity: 0, duration: 0.4, ease: EASE.out }, "+=3.2")
          .to(shape.current, { scaleX: 0.42, scaleY: 0.4, duration: DUR.m }, "-=0.2");
      }),
    [],
  );

  // Pointer-driven tilt, max 4deg, springy. Off on touch and reduced motion.
  useEffect(() => {
    const el = tilt.current;
    const host = stage.current;
    if (!el || !host || prefersReducedMotion() || !isFinePointer()) return;
    gsap.set(el, { transformPerspective: 1400 });
    const rx = gsap.quickTo(el, "rotationX", { duration: 1, ease: "elastic.out(1, 0.7)" });
    const ry = gsap.quickTo(el, "rotationY", { duration: 1, ease: "elastic.out(1, 0.7)" });
    const move = (e: PointerEvent) => {
      const r = host.getBoundingClientRect();
      const x = ((e.clientX - r.left) / r.width - 0.5) * 2;
      const y = ((e.clientY - r.top) / r.height - 0.5) * 2;
      ry(Math.max(-1, Math.min(1, x)) * 4);
      rx(Math.max(-1, Math.min(1, y)) * -4);
    };
    const leave = () => {
      rx(0);
      ry(0);
    };
    host.addEventListener("pointermove", move);
    host.addEventListener("pointerleave", leave);
    return () => {
      host.removeEventListener("pointermove", move);
      host.removeEventListener("pointerleave", leave);
      gsap.set(el, { clearProps: "transform" });
    };
  }, []);

  const dry = face.mood === "asleep";
  const full = face.mood === "party";

  return (
    <div className={s.stage} ref={stage}>
      <div
        className={s.screen}
        ref={tilt}
        role="img"
        aria-label="Refill in the macOS menu bar: three accounts with live countdowns, usage bars that drain and refill, and Drip changing mood"
      >
        <div className={s.menubar} aria-hidden="true">
          <span className={s.apple}>&#63743;</span><b>Finder</b><span className={s.dim}>File</span><span className={s.dim}>Edit</span>
          <span className={s.spacer} />
          <span className={s.tank}><i ref={mbFill} /></span>
          <span ref={mbPct} className={s.pct}>72%</span>
          <span className={s.dim}>Wi-Fi</span><span>Tue 9:41</span>
        </div>
        <div className={s.notch} aria-hidden="true">
          <div className={s.shape} ref={shape} />
          <div className={s.toast} ref={toast}>
            <Drip mood="party" size={40} />
            <div><b>Tank&apos;s full</b><span>work: 5h session is fresh</span></div>
          </div>
        </div>
        <div className={s.desk} aria-hidden="true">
          <div className={s.term}>
            <div className={s.tdots}><i /><i /><i /></div>
            <p className={s.mono}><span className={s.dim}>~/app $</span> claude</p>
            <p className={s.mono}>&gt; refactor the auth module</p>
            {dry ? (
              <p className={`${s.mono} ${s.warnText}`}>5-hour limit reached. Resets in <span ref={(el) => { clocks.current[3] = el; }} /></p>
            ) : full ? (
              <p className={`${s.mono} ${s.okText}`}>Limit reset. Carry on.</p>
            ) : (
              <p className={s.mono}>Working<span className={s.caret} /></p>
            )}
          </div>
          <div className={s.popover}>
            <div className={s.phead}>
              <Drip mood={face.mood} pct={face.pct} size={88} />
              <div>
                <b>Refill</b>
                <span className={s.say}>{face.say}</span>
              </div>
            </div>
            {ACCOUNTS.map(([name, win], i) => (
              <div className={s.acct} key={name}>
                <div className={s.arow}>
                  <span>{name}</span><em>{win}</em>
                  <time ref={(el) => { clocks.current[i] = el; }}>00:00</time>
                  <b ref={(el) => { nums.current[i] = el; }}>72%</b>
                </div>
                <div className={s.track}><i ref={(el) => { bars.current[i] = el; }} /></div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
