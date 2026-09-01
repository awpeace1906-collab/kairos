# Kairos PWA shell

Offline-capable web client. Plain ES modules — **no build step for the app**.
Reads the shared `../content/` JSON (mirrored into `web/content/` for dev).

## Run

```bash
npm run dev          # runs the content pipeline + sync, then serves on :5173
# open http://localhost:5173
```

`npm run sync` alone regenerates `../content/{search-index,manifest}.json` and
copies the tree into `web/content/` (gitignored).

## What's wired

| Piece | File |
|---|---|
| Delivery state machine (cache-first, manifest check, OTA swap, bundled fallback) | `src/lib/contentStore.js` |
| Service worker precache of shell + bundled content | `sw.js` |
| Flat search index + Section→Category→Item TOC | `src/lib/search.js`, `src/views/home.js` |
| Calculator engine (`additive` / `formula` / `classification` / `external`) | `src/lib/calcEngine.js` + `src/lib/expr.js` |
| Dual-mode weight/zone (equipment from zone, dose always from exact weight) | `src/lib/weightZones.js`, drug-card view in `src/views/content.js` |
| Tier 6: per-field clear, "Clear fields", session persistence | `src/components.js`, `src/lib/session.js` |
| "Last verified" + flag-as-outdated | `components.js#lastVerified` |

## Enabling over-the-air content updates

In `src/lib/contentStore.js` set `REMOTE_BASE` to the CDN base that serves the
versioned `content/` tree. The store then polls `manifest.json`, background-fetches
only changed modules, and swaps them into the runtime cache without a reload.

## Not done here (scaffold)

- Real icons in `public/icons/` (referenced by the manifest).
- Procedure decision-tree walking UI (schema + stub only).
- The full content set — 10 example/stub modules ship; the rest is content work.
- Visual design — palette/typography is an open Tier 5 decision; `styles.css` uses
  neutral placeholder tokens.
