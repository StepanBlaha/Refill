"use client";

import { useEffect, useRef, useState } from "react";
import { NotchScene, NotifScene, SoundScene, WarnScene } from "./SignalVisuals";
import { gsap, ScrollTrigger, useReveal } from "@/lib/motion";
import c from "./Shared.module.css";
import s from "./Signals.module.css";

const STEPS = [
  { t: "Notch pop-up", d: "Drip slides down from the top of your screen.", Scene: NotchScene },
  { t: "Native notification", d: "Short, plain words from Drip.", Scene: NotifScene },
  { t: "Sound", d: "A chime you can actually tell apart from Slack.", Scene: SoundScene },
  { t: "Warnings too", d: "Nudges at 80% and 95%, and a dry-tank alert at 100%.", Scene: WarnScene },
];

export default function Signals() {
  const root = useRef<HTMLElement>(null);
  const story = useRef<HTMLDivElement>(null);
  const [active, setActive] = useState(0);
  useReveal(root, `.${s.head} > *`);

  // Desktop with motion: pin the story and step through it while scrolling.
  useEffect(() => {
    const mm = gsap.matchMedia();
    mm.add("(min-width: 900px) and (prefers-reduced-motion: no-preference)", () => {
      const st = ScrollTrigger.create({
        trigger: story.current,
        start: "top top+=56",
        end: `+=${STEPS.length * 70}%`,
        pin: true,
        anticipatePin: 1,
        onUpdate: (self) => setActive(Math.min(STEPS.length - 1, Math.floor(self.progress * STEPS.length))),
      });
      return () => {
        st.kill();
        setActive(0);
      };
    });
    return () => mm.revert();
  }, []);

  return (
    <section className={`${c.sec} ${c.alt}`} id="signals" ref={root}>
      <div className={c.wrap}>
        <div className={s.head}>
          <p className={c.eyebrow}>Signals</p>
          <h2 className={c.h2}>Know the second it refills.</h2>
          <p className={c.sub}>
            A limit resets. Refill notices, even if you were offline when it happened. Then it gets loud, in whatever
            way you like.
          </p>
        </div>
        <div className={s.story} ref={story}>
          <ol className={s.steps}>
            {STEPS.map(({ t, d, Scene }, i) => (
              <li className={s.step} key={t} data-active={active === i}>
                <span className={s.num} aria-hidden="true">0{i + 1}</span>
                <h3>{t}</h3>
                <p>{d}</p>
                <div className={s.inline} aria-hidden="true"><Scene /></div>
              </li>
            ))}
          </ol>
          <div className={s.stage} aria-hidden="true">
            {STEPS.map(({ t, Scene }, i) => (
              <div className={s.layer} key={t} data-on={active === i}>
                <Scene />
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
