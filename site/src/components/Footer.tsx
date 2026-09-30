import Link from "next/link";
import Drip from "./Drip";
import { DISCLAIMER, REPO } from "@/lib/site";
import s from "./Footer.module.css";

export default function Footer() {
  return (
    <footer className={s.foot}>
      <div className={s.row}>
        <Link className={s.brand} href="/" aria-label="Refill home">
          <Drip mood="happy" pct={100} size={26} />
          <span>Refill</span>
        </Link>
        <nav aria-label="Footer" className={s.nav}>
          <Link href="/privacy/">Privacy</Link>
          <Link href="/terms/">Terms</Link>
          <Link href="/notice/">Notice</Link>
          <a href={REPO}>GitHub</a>
          <a href={`${REPO}/issues`}>Issues</a>
        </nav>
        <p className={s.fine}>{DISCLAIMER}</p>
      </div>
    </footer>
  );
}
