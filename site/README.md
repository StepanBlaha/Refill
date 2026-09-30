# Refill site

Next.js (App Router, static export) + CSS Modules + GSAP ScrollTrigger + Locomotive Scroll v5 (Lenis).

- Dev: `npm install && npm run dev` (served under `/Refill`, e.g. http://localhost:3000/Refill/)
- Build: `npm run build` -> static site in `site/out`
- `NEXT_PUBLIC_BASE_PATH` sets the base path (default `/Refill`; set to an empty string for a root domain).
- Legal pages (privacy, terms, notice) are ported verbatim from the previous static site in `website/`.
