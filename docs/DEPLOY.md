# Deploying Kairos

One static bundle holds the whole thing:

```
dist/
  index.html  styles.css  sw.js  manifest.webmanifest  src/  public/   ← the PWA
  content/
    manifest.json      version + hash per module — the file clients poll
    search-index.json
    sources-index.json
    config/…
    modules/…
  _deploy.json           { generatedAt, files, contentBaseUrl }
```

The clients render from a bundled copy of `content/` and, when online, pull
updates from that `content/` tree — no server, no API (`ARCHITECTURE.md §2`).
A correction is: edit the JSON → add a `changelog` entry → bump
`content_version` → run the pipeline → publish. Because the client diffs per
module, only the changed file is re-fetched by every running app.

## Build the bundle

```bash
cd tools
CONTENT_BASE_URL=https://<owner>.github.io/<repo>/content/ npm run deploy
```

`npm run deploy` validates, regenerates `search-index.json` + `manifest.json`
(stamping `contentBaseHint` from `CONTENT_BASE_URL`), copies the PWA shell from
`web/` and the served content subset from `content/`, and writes `tools/dist/`.
Schemas are not shipped — clients don't validate at runtime.

## Publish it

`dist/` is a plain directory of static files.

| Host | How |
|---|---|
| **GitHub Pages** (default) | Push to `main`; `.github/workflows/deploy.yml` runs `npm run deploy` and publishes `dist/`. One-time setup below. |
| **S3 + CloudFront** | `aws s3 sync tools/dist/ s3://your-bucket/ --delete --cache-control "public,max-age=300"`, then invalidate `/content/manifest.json`. |
| **Cloudflare Pages / Netlify** | Point the project's build output at `tools/dist` (build command `cd tools && npm i && npm run deploy`). |

**Caching:** serve `content/manifest.json` with a short TTL (~5 min) so
corrections propagate; the per-module JSON can cache longer — a real change
always bumps `content_version` and the client re-fetches on mismatch.

### GitHub Pages — one-time setup (repo owner)

1. **Settings → Pages → Build and deployment → Source: “GitHub Actions”.**
   (Not “Deploy from a branch”.)
2. **Settings → Secrets and variables → Actions → Variables → New repository
   variable:** `CONTENT_BASE_URL` = `https://<owner>.github.io/<repo>/content/`
   — for this repo, `https://awpeace1906-collab.github.io/kairos/content/`.
3. Push to `main` (or run the **deploy** workflow manually). The app is then live
   at `https://<owner>.github.io/<repo>/` and the content tree at `…/content/`.

## The clients

- **Web** — served from the same bundle; `REMOTE_BASE` stays `null` (the content
  is same-origin `./content/` and the service worker refreshes it
  stale-while-revalidate). Only set it if the content moves to a different host.
- **iOS** — `ios/Sources/Content/ContentStore.swift`,
  `ContentStore.remoteBase` is set to
  `https://awpeace1906-collab.github.io/kairos/content/`. The app renders from
  its bundled copy, polls `manifest.json` on launch + in the background,
  downloads only modules whose `content_version` increased, and swaps them into
  the cache — no App Store submission. Set it back to `nil` to pin to the
  bundled content.

## Emergency single-fact fix

Same path, no special case: edit one module JSON, add a `changelog` entry, bump
`content_version`, `npm run deploy`, publish. Only that one file is re-fetched
by every app instance.
