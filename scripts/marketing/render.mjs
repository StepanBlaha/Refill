#!/usr/bin/env node
// Renders marketing stills from stage.html with Playwright (system Chrome).
// Usage, from the repo root:
//   npm install --prefix scripts/marketing playwright
//   node scripts/marketing/render.mjs
//   node scripts/marketing/render.mjs --only carousel-01,story-01
import { chromium } from "playwright-core";
import { spawn } from "node:child_process";
import { mkdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../..");
const stage = path.join(here, "stage.html");
const work = path.join(root, "marketing/social/.work");

const only = (() => {
  const i = process.argv.indexOf("--only");
  if (i === -1) return null;
  return new Set(process.argv[i + 1].split(",").map((s) => s.trim()).filter(Boolean));
})();

function seq(id, n, fileDir) {
  const out = [];
  for (let i = 0; i < n; i++) {
    const t = n === 1 ? 0 : i / (n - 1);
    out.push({
      shot: id,
      t,
      w: null,
      h: null,
      dsf: 1,
      file: path.join(fileDir, `${String(i).padStart(3, "0")}.png`),
    });
  }
  return out;
}

const social = [
  ["carousel-01", 1080, 1350],
  ["carousel-02", 1080, 1350],
  ["carousel-03", 1080, 1350],
  ["carousel-04", 1080, 1350],
  ["carousel-05", 1080, 1350],
  ["carousel-06", 1080, 1350],
  ["carousel-07", 1080, 1350],
  ["story-01", 1080, 1920],
  ["story-02", 1080, 1920],
  ["story-03", 1080, 1920],
  ["story-04", 1080, 1920],
  ["story-05", 1080, 1920],
  ["story-06", 1080, 1920],
  ["x-card", 1600, 900],
  ["hero-still", 1600, 1000],
  ["reel-cover", 1080, 1920],
].map(([shot, w, h]) => ({ shot, w, h, dsf: 1, file: path.join(root, "marketing/social", `${shot}.png`) }));

const squares = ["sq-01", "sq-02", "sq-03", "sq-04"].map((shot) => ({
  shot, w: 1080, h: 1080, dsf: 1, file: path.join(work, `${shot}.png`),
}));

const heroFrames = [
  { shot: "hero-a", w: 1600, h: 1000, dsf: 1, file: path.join(work, "hero-a.png") },
  { shot: "hero-still", w: 1600, h: 1000, dsf: 1, file: path.join(work, "hero-b.png") },
  { shot: "hero-b", w: 1600, h: 1000, dsf: 1, file: path.join(work, "hero-c.png") },
];

// Desktop compositions match Brink's 2880×1800 shot list (1440×900 at 2×).
const desks = [
  ["desk-menu", "01-menu-bar.png"],
  ["desk-notch", "02-notch-reset.png"],
  ["desk-history", "03-history.png"],
  ["desk-settings", "04-settings.png"],
  ["desk-accounts", "05-accounts.png"],
  ["desk-moods", "06-moods.png"],
].map(([shot, name]) => ({
  shot, w: 1440, h: 900, dsf: 2, file: path.join(root, "marketing/screenshots", name),
}));

// Same names `Refill --render` writes, so a Mac recapture replaces these files.
const ui = [
  { shot: "ui-menu", w: 340, h: 640, dsf: 2, clip: true, file: path.join(root, "marketing/screenshots/menu.png") },
  { shot: "ui-moods", w: 520, h: 200, dsf: 2, clip: true, file: path.join(root, "marketing/screenshots/moods.png") },
  { shot: "ui-settings", w: 640, h: 900, dsf: 2, file: path.join(root, "marketing/screenshots/settings.png") },
  { shot: "ui-history", w: 680, h: 560, dsf: 2, file: path.join(root, "marketing/screenshots/history.png") },
  { shot: "ui-accounts", w: 640, h: 700, dsf: 2, file: path.join(root, "marketing/screenshots/accounts.png") },
];

const gifDirs = {
  "menu-bar": path.join(root, "marketing/media/.frames/menu-bar"),
  "notch-reset": path.join(root, "marketing/media/.frames/notch-reset"),
  "notch-warning": path.join(root, "marketing/media/.frames/notch-warning"),
  history: path.join(root, "marketing/media/.frames/history"),
  install: path.join(root, "marketing/media/.frames/install"),
};

const frames = [
  ...seq("gif-menu", 16, gifDirs["menu-bar"]).map((f) => ({ ...f, w: 900, h: 640 })),
  ...seq("gif-notch", 14, gifDirs["notch-reset"]).map((f) => ({ ...f, w: 1200, h: 420 })),
  ...seq("gif-warn", 10, gifDirs["notch-warning"]).map((f) => ({ ...f, w: 1200, h: 420 })),
  ...seq("gif-history", 12, gifDirs.history).map((f) => ({ ...f, w: 760, h: 520 })),
  ...seq("gif-install", 12, gifDirs.install).map((f) => ({ ...f, w: 1100, h: 640 })),
];

function wanted(job) {
  if (!only) return true;
  return only.has(job.shot) || only.has(path.basename(job.file, ".png"));
}

async function shoot(browser, dsf, jobs) {
  if (!jobs.length) return;
  const context = await browser.newContext({
    deviceScaleFactor: dsf,
    viewport: { width: jobs[0].w, height: jobs[0].h },
  });
  const page = await context.newPage();
  for (const job of jobs) {
    mkdirSync(path.dirname(job.file), { recursive: true });
    await page.setViewportSize({ width: job.w, height: job.h });
    const q = new URLSearchParams({ shot: job.shot });
    if (job.t != null) q.set("t", String(job.t));
    await page.goto(`file://${stage}?${q}`, { waitUntil: "load" });
    await page.waitForSelector("#ready[data-ok='1']", { timeout: 15000, state: "attached" });
    if (job.clip) {
      const box = await page.locator("#stage").boundingBox();
      await page.screenshot({ path: job.file, clip: box, type: "png" });
    } else {
      await page.screenshot({ path: job.file, type: "png" });
    }
    process.stdout.write(`  ${path.relative(root, job.file)}\n`);
  }
  await context.close();
}

const all = [...social, ...squares, ...heroFrames, ...desks, ...ui, ...frames].filter(wanted);
if (!all.length) {
  console.error("No shots matched --only");
  process.exit(1);
}

const browser = await chromium.launch({
  channel: "chrome",
  headless: true,
  args: ["--no-sandbox", "--disable-dev-shm-usage", "--force-color-profile=srgb", "--font-render-hinting=slight"],
});

const byScale = new Map();
for (const job of all) {
  const k = job.dsf || 1;
  if (!byScale.has(k)) byScale.set(k, []);
  byScale.get(k).push(job);
}
for (const [dsf, jobs] of byScale) await shoot(browser, dsf, jobs);
await browser.close();

if (!only) {
  await new Promise((resolve, reject) => {
    const child = spawn("bash", [path.join(here, "video.sh")], { cwd: root, stdio: "inherit" });
    child.on("exit", (code) => (code === 0 ? resolve() : reject(new Error(`video.sh exited ${code}`))));
  });
}
