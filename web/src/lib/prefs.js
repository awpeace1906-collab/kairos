// Durable user preferences — survive a full closeout, unlike `session` (which is
// scratch state, cleared on cold launch). localStorage-backed.

const KEY = "kairos.prefs.v1";

function readAll() {
  try {
    return JSON.parse(localStorage.getItem(KEY) || "{}");
  } catch {
    return {};
  }
}
function writeAll(obj) {
  try {
    localStorage.setItem(KEY, JSON.stringify(obj));
  } catch { /* private mode — prefs just won't persist */ }
}

export const prefs = {
  get(key, fallback = null) {
    const v = readAll()[key];
    return v === undefined ? fallback : v;
  },
  set(key, value) {
    const all = readAll();
    if (value === null || value === undefined) delete all[key];
    else all[key] = value;
    writeAll(all);
  },
};

/** The active care-setting lens id (from config/settings.json), or null for "no lens". */
export const CARE_SETTING_KEY = "careSetting";
export function activeCareSetting() {
  return prefs.get(CARE_SETTING_KEY, null);
}

/** The peds lens — a boolean toggle, orthogonal to the care-setting lens. When on,
    peds/neonate modules float to the top of any list (a lens, never a filter). */
export const PEDS_LENS_KEY = "pedsLens";
export function activePedsLens() {
  return prefs.get(PEDS_LENS_KEY, false) === true;
}

/** Home-screen pins. Stored as an array of module ids once the user customizes;
    until then `null` = "use the curated defaults from config/pinned.json". */
export const PINS_KEY = "pins";
const MAX_PINS = 8;

/** Effective pinned id list — the user's list if they've customized, else curated. */
export function pinnedIds(curatedIds = []) {
  const v = prefs.get(PINS_KEY, null);
  return Array.isArray(v) ? v : curatedIds.slice();
}
export function isPinned(id, curatedIds = []) {
  return pinnedIds(curatedIds).includes(id);
}
/** Toggle `id`; returns the new pinned state (true = now pinned). */
export function togglePin(id, curatedIds = []) {
  const cur = pinnedIds(curatedIds);
  const i = cur.indexOf(id);
  let next;
  if (i === -1) next = [...cur, id].slice(-MAX_PINS);
  else next = cur.filter((x) => x !== id);
  prefs.set(PINS_KEY, next);
  return next.includes(id);
}
