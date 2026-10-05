"use client";

import { useEffect, useRef } from "react";
import { gsap, prefersReducedMotion } from "@/lib/motion";
import s from "./LiveBar.module.css";

type Props = {
  label?: string;
  /** Resting value in percent, shown under reduced motion. */
  rest: number;
  /** Loop between these two percent values. */
  range: [number, number];
  duration?: number;
  delay?: number;
  tiny?: boolean;
};

const tone = (l: number) => (l < 10 ? "var(--danger)" : l < 30 ? "var(--warn)" : "var(--accent)");

/** A usage bar that drifts between two values. Pauses when off screen. Transform only. */
export default function LiveBar({ label, rest, range, duration = 4, delay = 0, tiny }: Props) {
  const host = useRef<HTMLDivElement>(null);
  const fill = useRef<HTMLElement>(null);
  const num = useRef<HTMLElement>(null);

  useEffect(() => {
    const paint = (v: number) => {
      if (fill.current) {
        fill.current.style.transform = `scaleX(${v / 100})`;
        fill.current.style.background = tone(v);
      }
      if (num.current) num.current.textContent = `${Math.round(v)}%`;
    };
    paint(rest);
    if (prefersReducedMotion()) return;
    const state = { v: range[0] };
    const tw = gsap.to(state, {
      v: range[1],
      duration,
      delay,
      ease: "sine.inOut",
      repeat: -1,
      yoyo: true,
      onUpdate: () => paint(state.v),
    });
    const io = new IntersectionObserver(([e]) => (e.isIntersecting ? tw.play() : tw.pause()));
    if (host.current) io.observe(host.current);
    return () => {
      io.disconnect();
      tw.kill();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className={`${s.row} ${tiny ? s.tiny : ""}`} ref={host} data-bar>
      {label && <span className={s.label}>{label}</span>}
      <span className={s.track} aria-hidden="true"><i ref={fill} /></span>
      <b ref={num} aria-hidden="true">{rest}%</b>
    </div>
  );
}
