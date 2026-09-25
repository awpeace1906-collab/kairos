// Prose rendering shared by every content view: content lists, and prose
// fields in the Kairos text format (lib/richText.js). Mirrors
// ios/Sources/Views/Components/ContentListView.swift and RichText.swift.
import { el } from "../components.js";
import { parseRichText, leadLabel, tableColumnWeights, shouldStackTable } from "../lib/richText.js";

/** A "Term: the rest of the sentence" list item gets its lead term bolded —
    purely presentational (never changes the text), and degrades to plain text
    for any item that isn't shaped that way. Short lead-in only (<=7 words) so
    a colon appearing mid-sentence in ordinary prose doesn't get misread as a label. */
function listItem(item) {
  // An item is either a plain string (leaf) or { text, items?, ordered? }.
  const text = typeof item === "string" ? item : item?.text ?? "";
  const children = typeof item === "string" ? null : item?.items;

  const m = /^([^:]{2,50}):\s(.+)$/s.exec(text);
  const lead =
    m && m[1].trim().split(/\s+/).length <= 7
      ? [el("strong", {}, m[1] + ":"), " " + m[2]]
      : [text];

  return el(
    "li",
    {},
    ...lead,
    children?.length ? renderList(children, item.ordered) : null,
  );
}

/** A list at any nesting level. `ordered` numbers this level only. */
export function renderList(items, ordered) {
  return el(
    ordered ? "ol" : "ul",
    ordered ? { class: "numbered" } : {},
    (items || []).map(listItem),
  );
}

function line(text) {
  const lab = leadLabel(text);
  return lab ? [el("strong", {}, lab[0]), lab[1] ? " " + lab[1] : null] : [text];
}

/** Render a prose field. A plain one-line string stays a single <p class=cls>,
    exactly as before the text format existed; anything with paragraphs, line
    breaks or list lines becomes a `.rich` container of <p>, <ul> and <ol>. */
export function richText(text, cls) {
  if (text == null || text === "") return null;
  const out = parseRichText(text).map((b) =>
    b.type === "list"
      ? renderList(b.items, b.ordered)
      : el("p", {}, b.lines.map((l, i) => [i ? el("br") : null, ...line(l)]))
  );
  if (out.length === 1 && out[0].tagName === "P") {
    if (cls) out[0].className = cls;
    return out[0];
  }
  return el("div", { class: cls ? `rich ${cls}` : "rich" }, out);
}

/** A table block. Every row shares one set of column widths (a <colgroup>
    under table-layout: fixed), so header and cells line up. Tables that would
    not read well on a phone (see shouldStackTable) also carry `.stack`: under
    600px styles.css re-flows each row into a card, with the first cell as its
    title and every other cell labeled by its column header, so nothing
    scrolls sideways. */
export function renderTable(columns, rows) {
  columns = columns || [];
  rows = rows || [];
  const weights = tableColumnWeights(columns, rows);
  const stack = shouldStackTable(columns, rows);
  // A two-column card is a title plus its text: no per-value label needed.
  const cls = stack ? (weights.length === 2 ? "table-wrap stack pair" : "table-wrap stack") : "table-wrap";
  return el(
    "div",
    { class: cls },
    el(
      "table",
      {},
      el("colgroup", {}, weights.map((w) => el("col", { style: `width:${(w * 100).toFixed(1)}%` }))),
      columns.length ? el("thead", {}, el("tr", {}, columns.map((c) => el("th", {}, c)))) : null,
      el("tbody", {}, rows.map((row) =>
        el("tr", {}, row.map((cell, i) => el("td", { "data-label": columns[i] || "" }, richText(cell)))))
      )
    )
  );
}
