"use client";

import { useEffect, useRef, useState } from "react";
import Drip from "./Drip";
import { DMG, REPO, RELEASES_API } from "@/lib/site";
import { gsap, motionSafe } from "@/lib/gsap";
import c from "./Shared.module.css";
import s from "./Download.module.css";

export default function Download() {
  const root = useRef<HTMLElement>(null);
  const [version, setVersion] = useState<string | null>(null);

  // Latest release tag; any failure (404, offline, rate limit) just hides the label.
  useEffect(() => {
    const ctl = new AbortController();
    fetch(RELEASES_API, { signal: ctl.signal, headers: { Accept: "application/vnd.github+json" } })
      .then((r) => (r.ok ? r.json() : null))
      .then((j) => {
        const tag = j && typeof j.tag_name === "string" ? j.tag_name : null;
        if (tag) setVersion(tag);
      })
      .catch(() => {});
    return () => ctl.abort();
  }, []);

  useEffect(
    () =>
      motionSafe(root.current, () => {
        gsap.from(`.${s.in} > *`, {
          opacity: 0,
          y: 28,
          duration: 0.9,
          ease: "power3.out",
          stagger: 0.09,
          scrollTrigger: { trigger: root.current, start: "top 75%", once: true },
        });
      }),
    [],
  );

  return (
    <section className={`${c.sec} ${s.cta}`} id="download" ref={root}>
      <div className={`${c.wrap} ${s.in}`}>
        <Drip mood="party" size={96} />
        <h2 className={c.h2}>Get Refill.</h2>
        <p className={c.sub}>Lives in your menu bar. Costs nothing. Judges nobody.</p>
        <div className={s.row}>
          <a className={`${c.btn} ${s.lg}`} href={DMG}>Download for macOS</a>
          <a className={`${c.btn} ${c.ghost} ${s.lg}`} href={REPO}>View on GitHub</a>
        </div>
        <p className={c.fine}>
          macOS 14+ &middot; free &amp; open source &middot; first launch: right-click &rarr; Open
        </p>
        {version && <p className={s.ver}>Latest release: {version}</p>}
      </div>
    </section>
  );
}
