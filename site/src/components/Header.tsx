"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import Drip from "./Drip";
import { useScrollTo } from "./SmoothScroll";
import s from "./Header.module.css";

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

  const onClick = (hash: string) => (e: React.MouseEvent) => {
    if (!home) return; // real navigation to /#section
    e.preventDefault();
    scrollTo(hash);
  };

  return (
    <header className={s.bar}>
      <div className={s.inner}>
        <Link className={s.brand} href="/" aria-label="Refill home" onClick={home ? onClick("#top") : undefined}>
          <Drip mood="happy" pct={100} size={26} />
          <span>Refill</span>
        </Link>
        <nav aria-label="Primary" className={s.nav}>
          {NAV.map(([h, label]) => (
            <a key={h} href={home ? h : `/${h}`} onClick={onClick(h)}>
              {label}
            </a>
          ))}
        </nav>
        <a className={s.btn} href={home ? "#download" : "/#download"} onClick={onClick("#download")}>
          Download
        </a>
      </div>
    </header>
  );
}
