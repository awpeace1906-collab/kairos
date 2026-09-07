// Care-setting lens (DIRECTIONS_FORWARD.md §1). A LENS, not a fork: given the
// active setting id, reorder a list of search-index entries so the ones this
// setting emphasises float up. Never filters anything out.

/**
 * Emphasis rank for an entry under a setting. Lower = more relevant.
 *  - 0 .. n-1  : position of the setting in the entry's `settingEmphasis` array
 *  - Infinity  : entry doesn't list this setting (or has no emphasis) → unranked
 */
export function emphasisRank(entry, settingId) {
  if (!settingId) return Infinity;
  const arr = entry.settingEmphasis;
  if (!Array.isArray(arr) || !arr.length) return Infinity;
  const i = arr.indexOf(settingId);
  return i === -1 ? Infinity : i;
}

/** Stable reorder: emphasised entries first (by their emphasis position), the
    rest keep their original relative order. */
export function applyLens(entries, settingId) {
  if (!settingId) return entries;
  return entries
    .map((e, i) => ({ e, i, r: emphasisRank(e, settingId) }))
    .sort((a, b) => a.r - b.r || a.i - b.i)
    .map((x) => x.e);
}
