import type { Metadata } from "next";

export const BASE = process.env.NEXT_PUBLIC_BASE_PATH ?? "/Refill";
export const SITE_URL = "https://stepanblaha.github.io/Refill/";
export const REPO = "https://github.com/StepanBlaha/Refill";
export const ISSUES = `${REPO}/issues`;
export const DMG = `${REPO}/releases/latest/download/Refill.dmg`;
export const RELEASES_API = "https://api.github.com/repos/StepanBlaha/Refill/releases/latest";
export const AUTHOR = { name: "Stepan Blaha", url: "https://github.com/StepanBlaha" };
export const DISCLAIMER =
  "Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.";

export const HOME_TITLE = "Refill: Your AI tanks, watched.";
export const HOME_DESC =
  "Refill is a free, open-source macOS menu-bar app that watches your Claude, Codex, Copilot, Cursor and Gemini usage limits and signals the second they reset.";

/** Absolute URL for a site path ("" = home, "privacy/" etc). */
export const abs = (path: string) => SITE_URL + path;

/** Per-page metadata: title, description, OG, twitter, canonical. */
export function pageMeta(opts: {
  title: string;
  description: string;
  path: string; // "" for home, "privacy/" etc.
  noindex?: boolean;
}): Metadata {
  const url = abs(opts.path);
  const image = abs("og.png");
  const alt = "Refill, a macOS menu-bar app that watches your AI usage limits";
  return {
    title: { absolute: opts.title },
    description: opts.description,
    // The 404 page has no canonical URL of its own.
    alternates: opts.noindex ? undefined : { canonical: url },
    robots: opts.noindex ? { index: false, follow: true } : undefined,
    openGraph: {
      type: "website",
      siteName: "Refill",
      locale: "en_US",
      title: opts.title,
      description: opts.description,
      url,
      images: [{ url: image, width: 1200, height: 630, alt }],
    },
    twitter: {
      card: "summary_large_image",
      title: opts.title,
      description: opts.description,
      images: [{ url: image, alt }],
    },
  };
}
