// Kairos text format — the small amount of structure a prose field may carry.
//
// Content stays plain strings (no Markdown dependency, nothing to escape), but
// a long instruction reads far better broken up than as one run-on paragraph:
//
//   blank line          -> new paragraph
//   "- text"            -> bullet ("• " also accepted)
//   "1. text"           -> numbered item ("1)" also accepted)
//   two-space indent    -> nested one level under the previous item
//   any other newline   -> line break inside the paragraph
//   "LEVEL: text"       -> an ALL-CAPS lead label at the start of a paragraph
//                          is shown bold (see leadLabel)
//
// Pure: returns a plain block tree, so tools/test.mjs can exercise it and both
// renderers stay in step. Mirrors ios/Sources/Views/Components/RichText.swift —
// keep the two in sync.

const BULLET = /^(\s*)[-•]\s+(.*)$/;
const NUMBER = /^(\s*)\d{1,2}[.)]\s+(.*)$/;

/** @returns {Array<{type:"p", lines:string[]} | {type:"list", ordered:boolean, items:Array<{text:string, ordered:boolean, items:any[]}>}>} */
export function parseRichText(text) {
  const blocks = [];
  let cur = null; // the block currently being filled
  const lines = String(text ?? "").replace(/\r\n?/g, "\n").split("\n");

  for (const raw of lines) {
    if (raw.trim() === "") { cur = null; continue; }
    const m = BULLET.exec(raw) || NUMBER.exec(raw);
    if (m) {
      const ordered = !BULLET.test(raw);
      const nested = m[1].length >= 2;
      const item = { text: m[2].trim(), ordered: false, items: [] };
      if (nested && cur?.type === "list" && cur.items.length) {
        const parent = cur.items[cur.items.length - 1];
        if (!parent.items.length) parent.ordered = ordered;
        parent.items.push(item);
        continue;
      }
      if (cur?.type !== "list" || cur.ordered !== ordered) {
        cur = { type: "list", ordered, items: [] };
        blocks.push(cur);
      }
      cur.items.push(item);
      continue;
    }
    // A plain line: an indented one continues the last list item; otherwise
    // it breaks the line inside the current paragraph, or starts one.
    if (cur?.type === "list" && /^\s{2,}/.test(raw)) {
      const last = cur.items[cur.items.length - 1];
      (last.items.length ? last.items[last.items.length - 1] : last).text += " " + raw.trim();
      continue;
    }
    if (cur?.type !== "p") {
      cur = { type: "p", lines: [] };
      blocks.push(cur);
    }
    cur.lines.push(raw.trim());
  }
  return blocks;
}

/** True when the text needs more than one plain paragraph line to render. */
export function isStructured(text) {
  const b = parseRichText(text);
  return b.length > 1 || (b.length === 1 && (b[0].type !== "p" || b[0].lines.length > 1));
}

/** "LEVEL: rest" -> ["LEVEL:", "rest"] when the lead is an ALL-CAPS label of
    at most six words; otherwise null. All-caps only, so an ordinary sentence
    containing a colon is never mistaken for a label. */
export function leadLabel(line) {
  const m = /^([A-Z0-9][A-Z0-9 ,'’()/&+-]{1,48}):\s+(.+)$/s.exec(line);
  if (!m || !/[A-Z]{2}/.test(m[1]) || m[1].trim().split(/\s+/).length > 6) return null;
  return [m[1] + ":", m[2]];
}

/** Relative column widths for a table, shared by the header and every row so
    the columns always line up. Wordier columns get more room, damped by a
    square root so one long cell can't starve the rest. No column drops below
    ~60% of an even share, nor below the width its longest word needs on a
    phone (~30 characters across, less cell padding), so "pneumothorax" never breaks mid-word.
    Mirrors TableBlock.weights in Swift. */
export const PHONE_LINE_CHARS = 30;
export function tableColumnWeights(columns, rows) {
  const n = Math.max(columns?.length ?? 0, ...(rows ?? []).map((r) => r.length), 1);
  const cellsOf = (c) => [...(rows ?? []).map((r) => String(r[c] ?? ""))];
  const raw = Array.from({ length: n }, (_, c) => {
    const cells = [String(columns?.[c] ?? ""), ...cellsOf(c)];
    const avg = cells.reduce((s, x) => s + x.length, 0) / cells.length;
    return Math.sqrt(Math.max(avg, 4));
  });
  const floor = 0.6 / n;
  const wordMin = Array.from({ length: n }, (_, c) => {
    const longest = Math.max(0, ...cellsOf(c).flatMap((x) => x.split(/\s+/)).map((w) => w.length));
    return Math.min((longest + 3) / PHONE_LINE_CHARS, 0.45);
  });
  // Pin any column that would fall under its minimum at that minimum, share
  // what is left among the others in proportion, and repeat until stable —
  // so a minimum is never undone by the final normalization.
  const mins = wordMin.map((m) => Math.max(m, floor));
  const minSum = mins.reduce((a, b) => a + b, 0);
  if (minSum >= 1) return mins.map((m) => m / minSum);
  const pinned = new Set();
  let w = raw;
  for (let pass = 0; pass <= n; pass++) {
    const free = raw.map((_, c) => c).filter((c) => !pinned.has(c));
    const rest = 1 - [...pinned].reduce((a, c) => a + mins[c], 0);
    const freeRaw = free.reduce((a, c) => a + raw[c], 0);
    w = raw.map((x, c) => (pinned.has(c) ? mins[c] : (x / freeRaw) * rest));
    const under = free.filter((c) => w[c] < mins[c]);
    if (!under.length) break;
    under.forEach((c) => pinned.add(c));
  }
  return w;
}

/** Tables at least this wide become stacked row cards on a phone-width screen. */
export const STACK_TABLE_COLUMNS = 3;

/** On a phone, stack a table into row cards when it has three or more columns,
    or two where the second is running prose (averaging over 60 characters) —
    a label beside a paragraph leaves the paragraph a thin, very tall strip.
    Mirrors TableBlock.shouldStack in Swift. */
export function shouldStackTable(columns, rows) {
  const n = Math.max(columns?.length ?? 0, ...(rows ?? []).map((r) => r.length), 1);
  if (n >= STACK_TABLE_COLUMNS) return true;
  if (n < 2 || !rows?.length) return false;
  const avg = rows.reduce((a, r) => a + String(r[1] ?? "").length, 0) / rows.length;
  return avg > 60;
}
