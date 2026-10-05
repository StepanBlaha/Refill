"use client";

import { useEffect, useRef, useState } from "react";
import Drip from "./Drip";
import Status from "./Status";
import Arrow from "./Arrow";
import CopyCommand from "./CopyCommand";
import { BREW, DMG, INSTALL_SH, RELEASES_API, REPO, ZIP } from "@/lib/site";
import { DUR, EASE, STAGGER, gsap, motionSafe } from "@/lib/motion";
import c from "./Shared.module.css";
import s from "./Download.module.css";

const XATTR = "xattr -dr com.apple.quarantine /Applications/Refill.app";

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
        gsap.from(`.${s.rv}`, {
          opacity: 0,
          y: 28,
          duration: DUR.l,
          ease: EASE.out,
          stagger: STAGGER,
          clearProps: "transform,opacity",
          scrollTrigger: { trigger: root.current, start: "top 72%", once: true },
        });
        gsap.to(`.${s.drip}`, { y: -8, duration: 1.6, ease: "sine.inOut", repeat: -1, yoyo: true });
      }),
    [],
  );

  return (
    <section className={`${c.sec} ${s.cta}`} id="download" ref={root}>
      <div className={`${c.wrap} ${s.in}`}>
        <div className={s.rv}><div className={s.drip}><Drip mood="party" size={128} /></div></div>
        <h2 className={`${c.h2} ${s.big} ${s.rv}`}>Get Refill.</h2>
        <p className={`${c.sub} ${s.rv}`}>Lives in your menu bar. Costs nothing. Judges nobody.</p>
        <div className={`${s.row} ${s.rv}`}>
          <a className={`${c.btn} ${s.lg}`} href={DMG}>Download for macOS <Arrow /></a>
          <a className={`${c.btn} ${c.ghost} ${s.lg}`} href={REPO}>View on GitHub <Arrow /></a>
        </div>
        <p className={`${c.fine} ${s.rv}`}>
          macOS 14+ &middot; free &amp; open source &middot; <a href={ZIP}>Refill.zip</a> also available
        </p>
        {version && <Status kind="success">Latest release: {version}</Status>}
        {failed && !version && (
          <Status kind="warning">Could not check the latest version. The download button still gets the newest release.</Status>
        )}

        <div className={`${s.ways} ${s.rv}`}>
          <div className={s.way}>
            <h3>Homebrew</h3>
            <CopyCommand command={BREW} label="Homebrew" />
          </div>
          <div className={s.way}>
            <h3>One line</h3>
            <CopyCommand command={INSTALL_SH} label="one-line install" />
          </div>
        </div>
        <p className={`${c.fine} ${s.rv}`}>
          It isn&apos;t notarized. Homebrew and the one-line installer clear the quarantine flag for you.
        </p>

        <details className={`${s.help} ${s.rv}`}>
          <summary>First launch from the disk image</summary>
          <div className={s.helpBody}>
            <p>
              Move Refill to Applications and open it. macOS will block it once. Go to System Settings &rarr; Privacy
              &amp; Security and click <b>Open Anyway</b>. If this release has no zip yet, use the disk image.
            </p>
            <p>Or clear the quarantine flag from Terminal:</p>
            <CopyCommand command={XATTR} label="quarantine" />
          </div>
        </details>
      </div>
    </section>
  );
}
