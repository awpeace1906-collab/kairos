# Palettes — for the Tier 5 colour-scheme decision

Kairos must read as visually distinct from **AnesCalc** and **CRISIS** (its two
companion apps). This file captures the reference palettes so a Kairos scheme can
be proposed that collides with neither.

## AnesCalc v2 (from `AnesthesiaCalc/Utilities/ThemeManager.swift`)

7 selectable themes; **default is `astmColors`**. System accent asset = `#1B3A6B`
(navy). Core theme colours:

| Theme | primary | secondary | accent | cardBg |
|---|---|---|---|---|
| **ASTM (default)** | `#1C2B3A` dark navy | `#2E4560` | `#C4A800` gold | `#F4F4F0` warm off-white |
| Navy & Gold | `#1B3A6B` | `#2E6DA4` | `#C9A24A` gold | `#EBF5FB` |
| Deep Teal | `#0D5C5C` | `#1A8F8F` | `#F0A500` amber | `#E0F5F5` |
| Midnight Red | `#7B0000` | `#B22222` | `#E8C048` gold | `#FDF0F0` |
| Slate Green | `#2D5016` | `#4A7A28` | `#E0A030` amber | `#EDF5E6` |
| Charcoal Blue | `#2C3E50` | `#34495E` | `#3498DB` blue | `#ECF0F1` |
| Purple Gray | `#4A3060` | `#7B5EA7` | `#F39C12` orange | `#F0EAF8` |

**Takeaway:** AnesCalc owns *dark navy / teal / charcoal / maroon grounds with
gold–amber–orange accents*, plus ASTM drug-class colours (yellow induction, red
NMB, sky-blue opioid, violet pressor, grey local…). The current Kairos placeholder
accent `#4bb3a7` sits right on AnesCalc's "Deep Teal" — **change it.**

Avoid for Kairos: teal grounds, gold/amber/orange accents, navy+gold.

## CRISIS (from `CRISIS/App/src/styles/tokens.css`, batch 2)

CRISIS is a React/Vite PWA. Single dark theme, tokens kept "1:1 with the source
documents".

| Token | Value | Role |
|---|---|---|
| `--bg` | `#0a0e14` | near-black blue-black ground |
| `--surface` / `--surface2` | `#111720` / `#182030` | cards |
| `--teal` | `#00d4aa` | **primary** (kicker text, step numbers, field labels) |
| `--blue` | `#2563eb` | secondary accent |
| `--red` | `#e84c4c` | alert / critical |
| `--amber` | `#f59e0b` | warning |
| `--purple` | `#a78bfa` | classification tag |
| `--text` / `--text2` / `--text3` | `#e8edf5` / `#8a9ab5` / `#4a5670` | |

Fonts: **Source Serif 4** (body), **Syne** (display / headings / step titles,
700–800 wt), **IBM Plex Mono** (badges, inline code). Dark-only. Serif body is a
deliberate "reference document" feel.

**CRISIS owns:** near-black ground, bright teal primary, the teal/blue/red/amber/
purple semantic accent set, serif body + Syne display.

## What Kairos must avoid (union of the two)

- **Teal as a signature** — both apps use it. Kairos's placeholder `#4bb3a7`
  collides with both. **Drop teal entirely.**
- **Gold / amber as the accent** — AnesCalc's signature.
- **Near-black `#0a0e14` ground + serif body** — CRISIS's signature.
- **Navy `#1B3A6B`/`#1C2B3A` ground + system sans + ASTM drug colours** — AnesCalc.

## Proposed Kairos direction (for review — not yet applied)

The niche left open: **light-first, geometric-sans, single cool non-teal accent.**

- **Mode:** light-primary with a proper dark parity (CRISIS is dark-only,
  AnesCalc defaults to a dark navy header over light cards — a genuinely
  light-first app reads as different).
- **Ground (light):** soft warm-neutral `#F7F6F4` / surface `#FFFFFF` / lines
  `#E4E1DB`. **Ground (dark):** warm charcoal `#1A1A1E` (not blue-black) /
  surface `#26262B`.
- **Accent:** one of —
  - **A. Cobalt-indigo** `#3D5AFE` (distinct from CRISIS's `#2563eb` by being
    more violet/saturated) — clean, "decisive".
  - **B. Deep coral** `#F0563A` — warm, energetic, unused by either app; risk:
    reads "alert".
  - **C. Plum / byzantium** `#7A2E6B` — sober, distinctive, no collision.
  Recommend **A (cobalt-indigo)** as primary with a warm neutral everything-else.
- **Severity colours** (bands): keep functional — green `#2E7D32` / amber
  `#B26A00` / red `#C62828` / (critical) `#8E1D2D`. These are semantic, not brand,
  so overlap with CRISIS is fine.
- **Type:** a single geometric sans throughout (e.g. **Inter** or **IBM Plex
  Sans**) — NOT serif (CRISIS), with a tighter display weight for headers. No
  per-section colour theming beyond a small section icon tint.
- **Section tokens:** replace the current `.teal/.indigo/.orange/.brown/.pink`
  map with muted, low-chroma tints of the neutral + accent so sections are
  distinguishable but the app doesn't look like a colour wheel.

Next: build a one-page swatch comparison (Kairos option A/B/C beside AnesCalc +
CRISIS) as an artifact for the call.

## Kairos — current (placeholder, to be replaced)

`web/styles.css` `:root` + `ios/Sources/App/Theme.swift`:
`--bg #0f1720`, `--surface #17212b`, `--accent #4bb3a7` (teal — collides), section
tokens map to `.teal/.indigo/.orange/.brown/.pink`.

## Direction once CRISIS palette is in hand

Likely candidates that dodge both: a **cool desaturated blue-violet or a deep
green-not-teal** ground with a **single cool accent** (e.g. a clean cyan-blue or a
muted coral), sans-serif with a distinct type scale. Propose 2-3 concrete token
sets with side-by-side swatches against AnesCalc + CRISIS.
