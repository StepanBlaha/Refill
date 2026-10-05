/** Guide content model. Plain data so the same content renders on the site and in docs/GUIDES.md. */
export type Block =
  | { t: "h"; x: string }
  | { t: "p"; x: string }
  | { t: "ol"; x: string[] }
  | { t: "ul"; x: string[] }
  | { t: "fields"; x: [string, string][] }
  | { t: "table"; head: string[]; x: string[][] }
  | { t: "code"; x: string; title?: string; copy?: boolean };

export type Section = {
  id: string;
  title: string;
  group: string;
  /** One line: what you get. */
  intro: string;
  blocks: Block[];
};
