# Deploying content

The clients render from a bundled copy of `content/` and, when online, pull
updates from a **static file host** — no server, no API (see
`ARCHITECTURE.md §2`). A correction is: edit the JSON → bump `content_version` →
run the pipeline → publish `dist/`.

## Build the deployable bundle

```bash
cd tools
CONTENT_BASE_URL=https://your-host.example/ npm run deploy
```

`npm run deploy` validates, regenerates `search-index.json` + `manifest.json`
(stamping `contentBaseHint` from `CONTENT_BASE_URL`), and assembles
`tools/dist/`:

```
dist/
  index.html          small landing page (so the bucket root isn't blank)
  manifest.json       version + hash per module — the file clients poll
  search-index.json
  config/…
  modules/…
  _deploy.json        { generatedAt, files, contentBaseUrl }
```

Schemas are not shipped — clients don't validate at runtime.

## Publish it

`dist/` is a plain directory of static files. Any of:

| Host | Command |
|---|---|
| **GitHub Pages** | Push to `main` — `.github/workflows/content-deploy.yml` runs `npm run deploy` and publishes `dist/`. Set `CONTENT_BASE_URL` as a repo **Variable** (Settings → Secrets and variables → Actions → Variables) to `https://<owner>.github.io/<repo>/`. |
| **S3 + CloudFront** | `aws s3 sync tools/dist/ s3://your-bucket/ --delete --cache-control "public,max-age=300"` then invalidate `/manifest.json`. |
| **Cloudflare Pages** | Point a Pages project at `tools/dist` as the build output, or `wrangler pages deploy tools/dist`. |

**Caching:** serve `manifest.json` with a short TTL (~5 min) so corrections
propagate quickly; the per-module JSON can be cached longer since a real change
always bumps `content_version` and the client re-fetches on a version mismatch.

## Point the clients at it

Once the bundle is live:

- **Web** — `web/src/lib/contentStore.js`, set `REMOTE_BASE` to the URL.
- **iOS** — `ios/Sources/Content/ContentStore.swift`, set `ContentStore.remoteBase`.

Both default to `null` (bundled content only). With it set, the store polls
`manifest.json` on launch + in the background, downloads only modules whose
`content_version` increased, and swaps them into the cache with no reload / no
App Store submission.

## Emergency single-fact fix

Same path, no special case: edit one module JSON, add a `changelog` entry, bump
`content_version`, `npm run deploy`, publish. Because the client diffs per
module, only that one file is re-fetched by every app instance.
