"use client";

import { useEffect, useRef, useState } from "react";
import Drip from "./Drip";
import Status from "./Status";
import { BREW, DMG, INSTALL_SH, RELEASES_API, REPO, ZIP } from "@/lib/site";
import { gsap, motionSafe } from "@/lib/gsap";
import c from "./Shared.module.css";
import s from "./Download.module.css";

export default function Download() {
  const root = useRef<HTMLElement>(null);
  const [version, setVersion] = useState<string | null>(null);
  const [failed, setFailed] = useState(false);

  // Latest release tag; any failure (404, offline, rate limit) shows a warning. The download link still works.
  useEffect(() => {
    const ctl = new AbortController();
    fetch(RELEASES_API, { signal: ctl.signal, headers: { Accept: "application/vnd.github+json" } })
      .then((r) => (r.ok ? r.json() : null))
      .then((j) => {
        const tag = j && typeof j.tag_name === "string" ? j.tag_name : null;
        if (tag) setVersion(tag);
        else setFailed(true);
      })
      .catch((e) => {
        if (e?.name !== "AbortError") setFailed(true);
      });
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
        <p className={c.fine}>It isn&apos;t notarized. These three ways still install it.</p>
        <ul className={s.ways}>
          <li>
            <h3>Homebrew</h3>
            <code className={s.cmd}>{BREW}</code>
          </li>
          <li>
            <h3>One line</h3>
            <code className={s.cmd}>{INSTALL_SH}</code>
          </li>
          <li>
            <h3>Download</h3>
            <p>
              <a href={ZIP}>Refill.zip</a> or <a href={DMG}>Refill.dmg</a>. If this release has no zip yet, use the
              disk image. Move Refill to Applications. Open it, then go to System Settings &rarr; Privacy &amp;
              Security and click <b>Open Anyway</b>. Or run{" "}
              <code>xattr -dr com.apple.quarantine /Applications/Refill.app</code>.
            </p>
            <div className={s.row}>
              <a className={`${c.btn} ${s.lg}`} href={DMG}>Download for macOS</a>
              <a className={`${c.btn} ${c.ghost} ${s.lg}`} href={REPO}>View on GitHub</a>
            </div>
          </li>
        </ul>
        <p className={c.fine}>
          Homebrew and the one-line installer clear the quarantine flag. macOS 14+ &middot; free &amp; open source
        </p>
        {version && <Status kind="success">Latest release: {version}</Status>}
        {failed && !version && (
          <Status kind="warning">Could not check the latest version. The download button still gets the newest release.</Status>
        )}
      </div>
    </section>
  );
}
