"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import Drip from "./Drip";
import Arrow from "./Arrow";
import { useScrollTo } from "./SmoothScroll";
import { BASE } from "@/lib/site";
import s from "./Header.module.css";

// Every entry maps to a real section id on the home page.
const NAV = [
  ["#tank", "Sources"],
  ["#signals", "Signals"],
  ["#wire", "Integrations"],
  ["#private", "Privacy"],
  ["#faq", "FAQ"],
] as const;

export default function Header() {
  const scrollTo = useScrollTo();
  const home = usePathname() === "/";
  const [open, setOpen] = useState(false);
  const bar = useRef<HTMLElement>(null);
  const toggle = useRef<HTMLButtonElement>(null);

  const close = useCallback((refocus = false) => {
    setOpen(false);
    if (refocus) toggle.current?.focus();
  }, []);

  // Esc closes, Tab wraps inside the header while the menu is open, resize to desktop closes.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") return close(true);
      if (e.key !== "Tab") return;
      const items = bar.current?.querySelectorAll<HTMLElement>("a[href], button");
      if (!items || !items.length) return;
      const first = items[0];
      const last = items[items.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    };
    const mq = window.matchMedia("(min-width: 768px)");
    const onMq = () => mq.matches && setOpen(false);
    document.addEventListener("keydown", onKey);
    mq.addEventListener("change", onMq);
    return () => {
      document.removeEventListener("keydown", onKey);
      mq.removeEventListener("change", onMq);
    };
  }, [open, close]);

  const onClick = (hash: string) => (e: React.MouseEvent) => {
    setOpen(false);
    if (!home) return; // real navigation to /#section
    e.preventDefault();
    scrollTo(hash);
  };

  // Off the home page, section links must carry the base path (plain <a> is not rewritten).
  const href = (h: string) => (home ? h : `${BASE}/${h}`);

  return (
    <header className={s.bar} ref={bar}>
      <div className={s.inner}>
        <Link className={s.brand} href="/" aria-label="Refill home" onClick={home ? onClick("#top") : () => setOpen(false)}>
          <Drip mood="happy" pct={100} size={26} />
          <span>Refill</span>
        </Link>
        <nav aria-label="Primary" id="primary-nav" className={`${s.nav} ${open ? s.open : ""}`}>
          {NAV.map(([h, label]) => (
            <a key={h} href={href(h)} onClick={onClick(h)}>
              {label}
            </a>
          ))}
        </nav>
        <div className={s.right}>
          <a className={s.btn} href={href("#download")} onClick={onClick("#download")}>
            Download <Arrow />
          </a>
          <button
            ref={toggle}
            type="button"
            className={s.burger}
            aria-expanded={open}
            aria-controls="primary-nav"
            aria-label={open ? "Close menu" : "Open menu"}
            onClick={() => setOpen((o) => !o)}
          >
            <span aria-hidden="true" />
          </button>
        </div>
      </div>
    </header>
  );
}
