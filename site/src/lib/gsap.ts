"use client";

import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

if (typeof window !== "undefined") {
  gsap.registerPlugin(ScrollTrigger);
}

/** Runs `setup` only when the user has not asked for reduced motion. Returns cleanup. */
export function motionSafe(scope: Element | null, setup: () => void): () => void {
  const mm = gsap.matchMedia(scope ?? undefined);
  mm.add("(prefers-reduced-motion: no-preference)", () => {
    setup();
  });
  return () => mm.revert();
}

export { gsap, ScrollTrigger };
