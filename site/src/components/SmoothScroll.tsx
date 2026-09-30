"use client";

import { createContext, useContext, useEffect, useRef } from "react";
import type LocomotiveScroll from "locomotive-scroll";
import { gsap, ScrollTrigger } from "@/lib/gsap";

type ScrollToFn = (target: string) => void;

const Ctx = createContext<ScrollToFn>((target) => {
  document.querySelector(target)?.scrollIntoView();
});

export const useScrollTo = () => useContext(Ctx);

/**
 * Locomotive Scroll v5 (Lenis under the hood), driven by the GSAP ticker so
 * ScrollTrigger reads the same smoothed scroll position. Disabled entirely
 * for prefers-reduced-motion.
 */
export default function SmoothScroll({ children }: { children: React.ReactNode }) {
  const loco = useRef<LocomotiveScroll | null>(null);

  useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    let cancelled = false;
    let cleanup = () => {};

    const start = async () => {
      if (reduce.matches) return;
      const { default: Loco } = await import("locomotive-scroll");
      if (cancelled) return;
      gsap.ticker.lagSmoothing(0);
      const instance = new Loco({
        lenisOptions: { lerp: 0.1, smoothWheel: true, anchors: false },
        autoStart: true,
        initCustomTicker: (render) => gsap.ticker.add(render),
        destroyCustomTicker: (render) => gsap.ticker.remove(render),
      });
      loco.current = instance;
      const onScroll = () => ScrollTrigger.update();
      instance.lenisInstance?.on("scroll", onScroll);
      ScrollTrigger.refresh();
      cleanup = () => {
        instance.lenisInstance?.off("scroll", onScroll);
        instance.destroy();
        loco.current = null;
        gsap.ticker.lagSmoothing(500, 33);
      };
    };

    start();
    const onChange = () => {
      cleanup();
      cleanup = () => {};
      start();
    };
    reduce.addEventListener("change", onChange);
    return () => {
      cancelled = true;
      reduce.removeEventListener("change", onChange);
      cleanup();
    };
  }, []);

  const scrollTo: ScrollToFn = (target) => {
    const el = document.querySelector(target);
    if (!el) return;
    const offset = -72;
    if (loco.current) loco.current.scrollTo(target, { offset, duration: 1.2 });
    else window.scrollTo({ top: el.getBoundingClientRect().top + window.scrollY + offset, behavior: "auto" });
    history.replaceState(null, "", target);
  };

  return <Ctx.Provider value={scrollTo}>{children}</Ctx.Provider>;
}
