import Link from "next/link";
import s from "./Legal.module.css";

export default function Legal({ children }: { children: React.ReactNode }) {
  return (
    <main className={s.legal} id="top">
      <Link className={s.back} href="/">
        &larr; Back to Refill
      </Link>
      {children}
    </main>
  );
}
