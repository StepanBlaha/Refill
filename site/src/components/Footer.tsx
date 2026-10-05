import Link from "next/link";
import Drip from "./Drip";
import { DISCLAIMER, ISSUES, REPO } from "@/lib/site";
import s from "./Footer.module.css";

export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className={s.foot}>
      <div className={s.row}>
        <Link className={s.brand} href="/" aria-label="Refill home">
          <Drip mood="happy" pct={100} size={26} />
          <span>Refill</span>
        </Link>
        <nav aria-label="Footer" className={s.nav}>
          <Link href="/guides/">Guides</Link>
          <Link href="/privacy/">Privacy</Link>
          <Link href="/terms/">Terms</Link>
          <Link href="/acknowledgements/">Acknowledgements</Link>
          <Link href="/press/">Press</Link>
          <Link href="/notice/">Notice</Link>
          <a href={REPO}>GitHub</a>
          <a href={ISSUES}>Contact (GitHub Issues)</a>
        </nav>
        <p className={s.fine}>{DISCLAIMER}</p>
        <p className={s.fine}>
          &copy; {year} Stepan Blaha &middot; <a href={`${REPO}/blob/main/LICENSE`}>MIT</a>
        </p>
      </div>
    </footer>
  );
}
