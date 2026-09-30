import Link from "next/link";
import JsonLd, { crumbsLd } from "./JsonLd";
import s from "./Legal.module.css";

type Crumb = { name: string; path: string };

/** Legal page shell. Pass `crumb` for the visible breadcrumb and BreadcrumbList JSON-LD. */
export default function Legal({ children, crumb }: { children: React.ReactNode; crumb?: Crumb }) {
  return (
    <main className={s.legal} id="top">
      {crumb ? (
        <>
          <nav className={s.crumbs} aria-label="Breadcrumb">
            <ol>
              <li><Link href="/">Refill</Link></li>
              <li aria-current="page">{crumb.name}</li>
            </ol>
          </nav>
          <JsonLd data={crumbsLd(crumb.name, crumb.path)} />
        </>
      ) : null}
      {children}
    </main>
  );
}
