// Fail when a module's content changed but its content_version did not go up.
//
// The iOS app only re-downloads a module over the air when content_version in
// the manifest is higher than the copy it has, so an edit without a bump never
// reaches installed apps — silently. This guard compares every changed module
// under content/modules/ against a base commit.
//
//   node check-version-bumps.mjs <base> [head]
//
// base  commit to compare against (CI passes the push's "before" SHA or the
//       PR base). Missing, all-zero or unknown base → skipped with a notice.
// head  commit to check; omitted = the working tree (use before committing).
//
// Parsed JSON is compared, so whitespace and key-order changes need no bump.
// New modules pass (the app downloads anything missing from its record);
// deleted modules pass.
import { execFileSync } from "node:child_process";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(fileURLToPath(new URL(".", import.meta.url)), "..");
const [base, head] = process.argv.slice(2);

const git = (...args) => execFileSync("git", args, { cwd: ROOT, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });

function skip(why) {
  console.log(`check-version-bumps: skipped — ${why}`);
  process.exit(0);
}

if (!base || /^0+$/.test(base)) skip("no base commit to compare against");
try { git("cat-file", "-e", `${base}^{commit}`); } catch { skip(`base ${base} is not in this checkout`); }

const range = head ? [base, head] : [base];
const changed = git("diff", "--name-only", "--diff-filter=M", ...range, "--", "content/modules")
  .split("\n").filter((p) => p.endsWith(".json"));

// Deterministic form: sort object keys recursively, keep array order.
const canon = (v) => Array.isArray(v) ? v.map(canon)
  : v && typeof v === "object" ? Object.fromEntries(Object.keys(v).sort().map((k) => [k, canon(v[k])]))
  : v;
const same = (a, b) => JSON.stringify(canon(a)) === JSON.stringify(canon(b));

const problems = [];
for (const path of changed) {
  const before = JSON.parse(git("show", `${base}:${path}`));
  const after = JSON.parse(head ? git("show", `${head}:${path}`) : await readFile(join(ROOT, path), "utf8"));
  if (same(before, after)) continue;
  const v0 = before.content_version ?? 0, v1 = after.content_version ?? 0;
  if (v1 <= v0) problems.push(`${path}: content changed but content_version ${v0} → ${v1} (must be > ${v0})`);
}

if (problems.length) {
  for (const p of problems) console.log(`::error file=${p.split(":")[0]}::${p}`);
  console.log(`\ncheck-version-bumps: ${problems.length} module(s) changed without a version bump.`);
  console.log("Installed iOS apps only fetch a module when content_version goes up — bump it and add a changelog entry.");
  process.exit(1);
}
console.log(`check-version-bumps: ok — ${changed.length} changed module(s), all bumped (or unchanged after parsing)`);
