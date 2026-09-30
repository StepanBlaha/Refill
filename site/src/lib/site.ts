import type { Metadata } from "next";

export const BASE = process.env.NEXT_PUBLIC_BASE_PATH ?? "/Refill";
export const SITE_URL = "https://stepanblaha.github.io/Refill/";
export const REPO = "https://github.com/StepanBlaha/Refill";
export const DMG = `${REPO}/releases/latest/download/Refill.dmg`;
export const RELEASES_API = "https://api.github.com/repos/StepanBlaha/Refill/releases/latest";
export const DISCLAIMER =
  "Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.";

export const HOME_TITLE = "Refill: Your AI tanks, watched.";
export const HOME_DESC =
  "Refill is a macOS menu-bar app that watches your Claude, Codex, Copilot, Cursor and Gemini usage limits and signals the second they reset.";

/** Per-page metadata: title, description, OG, twitter, canonical. */
export function pageMeta(opts: {
  title: string;
  description: string;
  path: string; // "" for home, "privacy/" etc.
  noindex?: boolean;
}): Metadata {
  const url = SITE_URL + opts.path;
  const image = `${SITE_URL}og.png`;
  return {
    title: { absolute: opts.title },
    description: opts.description,
    alternates: { canonical: url },
    robots: opts.noindex ? { index: false, follow: true } : undefined,
    openGraph: {
      type: "website",
      siteName: "Refill",
      title: opts.title,
      description: opts.description,
      url,
      images: [{ url: image, width: 1024, height: 1024, alt: "Refill, Drip the glass tank" }],
    },
    twitter: {
      card: "summary",
      title: opts.title,
      description: opts.description,
      images: [image],
    },
  };
}
