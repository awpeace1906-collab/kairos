// Small DOM helpers + the Tier 6 UI affordances.

export function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (k === "class") node.className = v;
    else if (k === "dataset") Object.assign(node.dataset, v);
    else if (k.startsWith("on") && typeof v === "function") node.addEventListener(k.slice(2).toLowerCase(), v);
    else if (v != null && v !== false) node.setAttribute(k, v === true ? "" : v);
  }
  mount(node, ...children);
  return node;
}

/** Append children, skipping null/false/undefined (native .append stringifies them). */
export function mount(parent, ...children) {
  for (const c of children.flat(Infinity)) {
    if (c == null || c === false || c === true) continue;
    parent.append(c.nodeType ? c : document.createTextNode(String(c)));
  }
  return parent;
}

/** Tier 6: iOS-style inline clear ("x in a circle") that clears just this field. */
export function clearableField({ id, label, unit, type = "number", value = "", min, max, onInput, onClear }) {
  const input = el("input", {
    id,
    type,
    inputmode: type === "number" ? "decimal" : null,
    value: value ?? "",
    min,
    max,
    onInput: (e) => onInput?.(e.target.value),
  });
  const clearBtn = el(
    "button",
    {
      type: "button",
      class: "clear-field",
      "aria-label": `Clear ${label}`,
      hidden: !String(value ?? "").length,
      onClick: () => {
        input.value = "";
        clearBtn.hidden = true;
        onClear?.();
        onInput?.("");
        input.focus();
      },
    },
    "✕"
  );
  input.addEventListener("input", () => {
    clearBtn.hidden = !input.value.length;
  });
  return el(
    "label",
    { class: "field" },
    el("span", { class: "field-label" }, label, unit ? el("span", { class: "unit" }, ` (${unit})`) : null),
    el("span", { class: "field-input" }, input, clearBtn)
  );
}

/** Tier 6: one button that clears every field on a multi-field screen. */
export function clearFieldsButton(onClick) {
  return el("button", { type: "button", class: "clear-all", onClick }, "Clear fields");
}

/** "Last verified" line + human-sourced staleness channel (Content Update spec §3). */
export function lastVerified(mod) {
  if (!mod.last_reviewed) return null;
  const d = new Date(mod.last_reviewed + "T00:00:00Z");
  const stamp = d.toLocaleDateString(undefined, { month: "short", year: "numeric" });
  const subject = encodeURIComponent(`Kairos content flag: ${mod.id} (v${mod.content_version})`);
  return el(
    "p",
    { class: "last-verified" },
    `Last verified ${stamp}`,
    " · ",
    el("a", { href: `mailto:content@kairos.example?subject=${subject}` }, "Flag as outdated")
  );
}

export function severityClass(sev) {
  return sev ? `sev-${sev}` : "";
}
