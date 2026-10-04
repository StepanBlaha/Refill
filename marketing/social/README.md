# Refill social assets

Sample accounts only (`stepan@example.cz`, `work@example.cz`, Codex). The history numbers drawn on the chart slides (~8%/h, a 71% peak, one reset today) are a picture of the chart, not a measurement. No user counts.

These were rendered from `scripts/marketing/stage.html` with Playwright and Chrome, then assembled with ffmpeg. The menu, Drip and the notch pill follow the Swift views. Type is SF Pro when that face is installed, otherwise Inter. Rebuild:

```bash
npm install --prefix scripts/marketing playwright-core
node scripts/marketing/render.mjs
```

Real app captures, when you have them, come from `scripts/capture-marketing.sh` on a Mac. That does not overwrite this folder.

## Instagram Stories (1080×1920, 250 px top and bottom kept free)

| File | Use |
|---|---|
| story-01.png | Hook: "I kept hitting the limit mid-task." |
| story-02.png | "So I put the tanks in the menu bar." |
| story-03.png | "What's left, on one black panel." Names Claude and Codex, so the non-affiliation line is on the image. |
| story-04.png | "The moment it refills, Drip says so." |
| story-05.png | "A warning before empty. A chart for the pace." |
| story-06.png | CTA: icon, "Free and open source.", the site, an empty rounded area for a link sticker, the non-affiliation line |

## Reel / TikTok / Shorts

| File | Use |
|---|---|
| reel.mp4 | 1080×1920, about 13 s, H.264, faststart, no audio (add audio in the app). The six story frames, a slow zoom and a short crossfade. |
| reel-cover.png | 1080×1920 cover frame |

## Carousel (IG and LinkedIn, 1080×1350)

| File | Use |
|---|---|
| carousel-01.png | Cover: name and tagline |
| carousel-02.png | The problem |
| carousel-03.png … 06.png | Menu, notch, history, signals |
| carousel-07.png | CTA: free, MIT, macOS 14+, the site, the non-affiliation line |

## X / LinkedIn

| File | Use |
|---|---|
| x-card.png | 1600×900 link card, "Your AI tanks, watched.", and the non-affiliation line |
| hero-still.png | 1600×1000 still of the menu open on the desktop, no caption |

`refill-square-1080.mp4` is 1080×1080, about 10 s, H.264, no audio: four square frames (cover, menu, notch, CTA) with the same crossfade.

Posts that name Claude, Codex, Copilot, Cursor, Gemini, Anthropic, OpenAI, GitHub or Google still need the line, in the image or in the caption: "Refill is an independent app, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google."
