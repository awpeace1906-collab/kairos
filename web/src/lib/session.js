// Tier 6: entered data survives backgrounding / app-switch, and is cleared only
// by a genuine full closeout. sessionStorage matches that lifecycle closely on
// iOS PWAs (kept while the tab/app is alive & backgrounded; gone on real close).

const KEY = "kairos.session.v1";

function readAll() {
  try {
    return JSON.parse(sessionStorage.getItem(KEY) || "{}");
  } catch {
    return {};
  }
}
function writeAll(obj) {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(obj));
  } catch { /* private mode — session state simply won't persist */ }
}

/** Per-screen scratch state, keyed by route. */
export const session = {
  get(route) {
    return readAll()[route] || {};
  },
  patch(route, partial) {
    const all = readAll();
    all[route] = { ...(all[route] || {}), ...partial };
    writeAll(all);
    return all[route];
  },
  clearScreen(route) {
    const all = readAll();
    delete all[route];
    writeAll(all);
  },
  clearField(route, field) {
    const all = readAll();
    if (all[route]) {
      delete all[route][field];
      writeAll(all);
    }
  },
  clearAll() {
    writeAll({});
  },
};
