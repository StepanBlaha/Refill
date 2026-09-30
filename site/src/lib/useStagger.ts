"use client";

import { useEffect, type RefObject } from "react";
import { gsap, motionSafe } from "./gsap";

/** Staggers `selector` children of `root` in when the section scrolls into view. */
export function useStagger(root: RefObject<HTMLElement | null>, selector: string, extra?: () => void) {
  useEffect(
    () =>
      motionSafe(root.current, () => {
        gsap.from(selector, {
          opacity: 0,
          y: 32,
          duration: 0.9,
          ease: "power3.out",
          stagger: 0.08,
          scrollTrigger: { trigger: root.current, start: "top 78%", once: true },
        });
        extra?.();
      }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );
}
