# Content Review & Update Architecture — Design Spec

**Why this exists:** the andexanet alfa market withdrawal (found during this review, not before) is the concrete case for why this needs to be architecture, not a habit. No amount of care at build time catches a fact that becomes wrong six weeks later. The app needs to be built so that correcting it is a content push, not an App Store resubmission — and so that stale content gets *found*, not just eventually noticed by luck the way andexanet was.

---

## Core architecture decision: content is data, not code

**Every piece of clinical content — calculator formulas, drug doses, reference text, procedure steps — lives in structured data files (JSON), never hardcoded into app/UI logic.** This isn't new to this spec; it's the same principle `Search_TOC_Design_Spec.md` already assumes (the search index is "generated from the same structured content data" used to render each section). This document extends that principle to cover how that data gets updated after launch, not just how it's organized at launch.

```json
{
  "id": "ref-anticoag-factor-xa-reversal",
  "section": "Reference Library",
  "category": "Anticoagulation / Reversal",
  "content_version": 3,
  "last_reviewed": "2026-08-30",
  "next_review_due": "2026-11-30",
  "review_tier": 1,
  "sources": ["PMC13110298", "Bekka et al. Br J Clin Pharmacol 2025"],
  "body": "...",
  "changelog": [
    {"version": 3, "date": "2026-08-30", "change": "Removed andexanet alfa as primary US recommendation following Dec 2025 market withdrawal; 4F-PCC now primary"},
    {"version": 2, "date": "2026-06-15", "change": "Added idarucizumab split-dose detail"}
  ]
}
```

Fields that matter for the update mechanism specifically (beyond what a normal content record needs):
- **content_version** — increments on any factual change, independent of app version
- **last_reviewed / next_review_due** — drives the staleness-surfacing described below
- **review_tier** — reuses the Tier system from `README_Build_Package.md`: Tier 1 content (drug doses, reversal agents, diagnostic thresholds) gets a short review cadence; stable math (anion gap formula, unit conversions) doesn't need one at all
- **sources** — so "why does this say X" has an answer without archaeology through old chat logs

---

## Delivery mechanism: remote-fetched, offline-cached, version-checked

**This app will be used at the bedside, often without reliable connectivity — offline capability isn't optional.** The mechanism has to satisfy both "correctable without a rebuild" and "works with no signal in a basement ED or a moving ambulance":

1. On launch (and periodically in the background when connectivity is available), the app checks a lightweight version manifest hosted on a CDN/static host — just version numbers per content module, not the content itself. Cheap, fast, doesn't block startup.
2. If the manifest shows a newer version for a module than what's cached locally, fetch just that module's updated JSON in the background.
3. The app always renders from the local cache. A background update swaps the cache silently; it doesn't interrupt an in-progress lookup, and there's no scenario where the app is unusable because it couldn't reach the server.
4. If the device has never been able to fetch anything (first install, no connectivity), the app ships with a complete content bundle built into the binary as the fallback — never "content unavailable."

This means correcting something like the andexanet situation is: edit the JSON, bump the version, push to the CDN. Every app instance picks it up next time it has connectivity — no App Store review cycle required, because no app binary changed.

**Build note:** this is a static-file CDN pattern (S3/Cloudflare Pages/GitHub Pages serving versioned JSON), not a database-backed API — there's no dynamic query need here, the content is the same for every user. Keep the infrastructure as simple as the problem actually is.

---

## Solo-maintainer update workflow

Given this is presently a one-person content pipeline (you), the workflow should fit how you already work rather than requiring new tooling:

1. Content JSON files live in a git repo (could be the same repo as the app, or a separate content repo — separate is cleaner since content updates shouldn't require an app rebuild).
2. A small script (run manually or on a git push) validates the JSON (schema check — did you break the format, did you forget to bump content_version) and publishes changed files to the CDN.
3. Committing a content change to that repo IS the update mechanism — no separate CMS, no admin UI to build and maintain. Git commit history becomes the changelog for free, on top of the in-file `changelog` array for user-facing "what changed" surfacing.

**Emergency single-item correction path:** for something urgent (another andexanet-style situation), the same mechanism handles it — edit one JSON file, bump its version, push. Because updates are per-module rather than one giant bundle, a single-fact fix doesn't require re-validating or re-shipping unrelated content.

---

## Surfacing staleness, not just fixing it reactively

The andexanet situation was caught by deliberately going back and re-checking — it wasn't flagged automatically. Two things worth building so the next one doesn't rely on remembering to look:

1. **A build-time or CI check** that flags any Tier 1 content item where `next_review_due` has passed. This can be as simple as a script that runs against the content repo and fails a check (or just emails you) — not a fancy dashboard, just a tripwire.
2. **User-facing "last verified" dates**, shown per content item (small, unobtrusive — a line under a drug card or reference topic: "Last verified Aug 2026"). This does two things: it's honest with the user about content freshness, and it creates a natural place for an in-app "flag this as outdated" button that routes back to you — a second, human-sourced channel for catching drift that a scheduled review might miss between cycles.

---

## Review cadence by tier (ties directly to the Tier system in `README_Build_Package.md`)

| Tier | Example content | Suggested review cadence |
|---|---|---|
| Tier 1 (drug doses, reversal agents, diagnostic thresholds, guideline-dependent algorithms) | Anticoagulation reversal, PALS/ACLS algorithms, peds resuscitation dosing, STEMI criteria | Every 3 months, or immediately on awareness of a relevant guideline/market change |
| Tier 3 (explicitly sourcing-dependent, already flagged as needing refresh) | Empiric antibiotic guide, vaccine schedule | Every 3 months, or immediately if the sourcing situation changes (e.g., vaccine litigation resolves) |
| Stable reference (validated calculator formulas, unit conversions, anatomy) | Anion gap formula, Cockcroft-Gault, ETT sizing formula | No scheduled review needed — these don't change; re-check only if a specific error is reported |

**This table itself should live in the content repo, not just this doc** — as content modules get built out, tag each one with its tier so the CI staleness check in the section above has something to check against.

---

## What this doesn't solve, and shouldn't try to

- **This isn't a substitute for periodic manual re-review passes** like the one that caught andexanet — the CI tripwire catches "you forgot," not "something changed that you didn't know to look for." Both are needed; this architecture makes the manual passes cheaper to act on once you find something, it doesn't replace the finding.
- **Not a multi-user CMS** — if this app ever grows beyond a solo content pipeline, this workflow (git commit → CDN push) would need a real interface. Not worth building now for a problem that doesn't exist yet.
