// The tripwire from Content_Update_Architecture_Spec.md: fail when any
// tripwire-eligible tiered item is past next_review_due. Not a dashboard — a
// build step that goes red so "you forgot to look" gets caught.
import { loadModules, loadConfig, iso } from "./lib/content.mjs";

const tiersCfg = await loadConfig("tiers.json");
const tripwireTiers = new Set(
  tiersCfg.tiers.filter((t) => t.tripwire).map((t) => String(t.tier))
);
const cadenceByTier = Object.fromEntries(
  tiersCfg.tiers.map((t) => [String(t.tier), t.cadenceDays])
);

const today = iso();
const mods = await loadModules();

const overdue = [];
const dueSoon = [];
const missing = [];

for (const mod of mods) {
  const j = mod.json;
  const tier = String(j.review_tier);
  if (!tripwireTiers.has(tier)) continue;

  if (!j.next_review_due) {
    missing.push(`${mod.relPath} (tier ${tier}) — no next_review_due`);
    continue;
  }
  if (j.next_review_due < today) {
    overdue.push(`${mod.relPath} (tier ${tier}) — due ${j.next_review_due}, last reviewed ${j.last_reviewed || "?"}`);
  } else if (daysBetween(today, j.next_review_due) <= 14) {
    dueSoon.push(`${mod.relPath} (tier ${tier}) — due ${j.next_review_due}`);
  }
}

if (dueSoon.length) {
  console.log("Due within 14 days:");
  for (const l of dueSoon) console.log("  ~ " + l);
}
if (missing.length) {
  console.log("\nTripwire tiers missing a review date:");
  for (const l of missing) console.log("  ! " + l);
}

const hardFail = overdue.length + missing.length;
if (overdue.length) {
  console.error("\nOVERDUE Tier-1/Tier-3 content — correct or re-review before shipping:");
  for (const l of overdue) console.error("  ✗ " + l);
}

console.log(`\ncheck-staleness: ${mods.length} modules scanned, ${overdue.length} overdue, ${missing.length} missing a date, ${dueSoon.length} due soon`);
if (hardFail) process.exit(1);
console.log("✓ no overdue tripwire content");

function daysBetween(a, b) {
  return Math.round((Date.parse(b) - Date.parse(a)) / 86_400_000);
}
