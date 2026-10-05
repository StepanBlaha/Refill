import Link from "next/link";
import CopyCommand from "./CopyCommand";
import JsonLd, { crumbsLd } from "./JsonLd";
import type { Block, Section } from "@/app/guides/types";
import l from "./Legal.module.css";
import s from "./Guide.module.css";

/** Inline markup: `code`, **bold**, [text](url). Nothing else. */
function inline(text: string): React.ReactNode[] {
  const out: React.ReactNode[] = [];
  const re = /`([^`]+)`|\*\*([^*]+)\*\*|\[([^\]]+)\]\(([^)]+)\)/g;
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text))) {
    if (m.index > last) out.push(text.slice(last, m.index));
    const k = out.length;
    if (m[1] !== undefined) out.push(<code key={k}>{m[1]}</code>);
    else if (m[2] !== undefined) out.push(<strong key={k}>{inline(m[2])}</strong>);
    else out.push(<a key={k} href={m[4]} rel="noopener">{m[3]}</a>);
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push(text.slice(last));
  return out;
}

function Table({ head, rows }: { head: string[]; rows: string[][] }) {
  return (
    <div className={s.tableWrap}>
      <table>
        <thead>
          <tr>{head.map((h) => <th key={h}>{h}</th>)}</tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i}>{r.map((c, j) => <td key={j}>{inline(c)}</td>)}</tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function BlockView({ b }: { b: Block }) {
  switch (b.t) {
    case "h": return <h3>{b.x}</h3>;
    case "p": return <p>{inline(b.x)}</p>;
    case "ol": return <ol>{b.x.map((i, k) => <li key={k}>{inline(i)}</li>)}</ol>;
    case "ul": return <ul>{b.x.map((i, k) => <li key={k}>{inline(i)}</li>)}</ul>;
    case "fields": return <Table head={["Field in Refill", "What to enter"]} rows={b.x.map(([a, c]) => [`**${a}**`, c])} />;
    case "table": return <Table head={b.head} rows={b.x} />;
    case "code":
      if (b.copy && !b.x.includes("\n")) {
        return <CopyCommand command={b.x} label={b.title ?? "setup"} />;
      }
      return (
        <figure className={s.fig}>
          {b.title ? <figcaption>{b.title}</figcaption> : null}
          <pre tabIndex={0}><code>{b.x}</code></pre>
        </figure>
      );
  }
}

export default function Guide({ sections }: { sections: Section[] }) {
  const groups = Array.from(new Set(sections.map((x) => x.group)));
  return (
    <main className={s.page} id="top">
      <nav className={l.crumbs} aria-label="Breadcrumb">
        <ol>
          <li><Link href="/">Refill</Link></li>
          <li aria-current="page">Guides</li>
        </ol>
      </nav>
      <JsonLd data={crumbsLd("Guides", "guides/")} />
      <header className={s.head}>
        <h1>Setup guides</h1>
        <p>Everything in Refill that needs setting up, step by step. Pick a section on the left.</p>
      </header>
      <div className={s.layout}>
        <nav className={s.toc} aria-label="On this page">
          {groups.map((g) => (
            <div key={g}>
              <p className={s.tocHead}>{g}</p>
              <ul>
                {sections.filter((x) => x.group === g).map((x) => (
                  <li key={x.id}><a href={`#${x.id}`}>{x.title}</a></li>
                ))}
              </ul>
            </div>
          ))}
        </nav>
        <div className={s.body}>
          {sections.map((x) => (
            <section key={x.id} id={x.id} className={s.sec} aria-labelledby={`${x.id}-h`}>
              <h2 id={`${x.id}-h`}>{x.title}</h2>
              <p className={s.lead}><strong>What you get.</strong> {inline(x.intro)}</p>
              {x.blocks.map((b, i) => <BlockView key={i} b={b} />)}
              <a className={s.up} href="#top">Back to top</a>
            </section>
          ))}
        </div>
      </div>
    </main>
  );
}
