"use client";

import { useEffect, type RefObject } from "react";
import { gsap, ScrollTrigger, motionSafe } from "./gsap";

/** Shared motion tokens so every section moves the same way. */
export const EASE = { out: "power3.out", expo: "expo.out", inOut: "power2.inOut" } as const;
export const DUR = { s: 0.6, m: 0.8, l: 0.9 } as const;
export const STAGGER = 0.06;

export const prefersReducedMotion = () =>
  typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

export const isFinePointer = () =>
  typeof window !== "undefined" && window.matchMedia("(hover: hover) and (pointer: fine)").matches;

/**
 * Reveals every `selector` match inside `root` (opacity + transform only) when
 * the section scrolls into view. Under reduced motion nothing is hidden, so
 * the content is simply there.
 */
export function useReveal(root: RefObject<HTMLElement | null>, selector: string, extra?: (el: HTMLElement) => void) {
  useEffect(() => {
    const el = root.current;
    if (!el) return;
    return motionSafe(el, () => {
      gsap.from(el.querySelectorAll(selector), {
        opacity: 0,
        y: 32,
        duration: DUR.l,
        ease: EASE.out,
        stagger: STAGGER,
        clearProps: "transform,opacity", // hand transforms back to CSS hover states
        scrollTrigger: { trigger: el, start: "top 78%", once: true },
      });
      extra?.(el);
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
}

/** Refresh trigger positions after fonts and images settle. Mounted once. */
export function useRefreshOnLoad() {
  useEffect(() => {
    const refresh = () => ScrollTrigger.refresh();
    document.fonts?.ready.then(refresh);
    window.addEventListener("load", refresh);
    return () => window.removeEventListener("load", refresh);
  }, []);
}

export { gsap, ScrollTrigger, motionSafe };
