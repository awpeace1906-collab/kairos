// ContentStore — the delivery state machine from Content_Update_Architecture_Spec.md.
//
//   render from cache, always  ->  check a lightweight manifest when online  ->
//   background-fetch only changed modules  ->  swap cache silently.
//
// Bundled fallback: web/content/ is precached by the service worker, so a first
// load with no connectivity still works. Mirrors ios/Sources/Content/ContentStore.swift.

const BUNDLED_BASE = new URL("../../content/", import.meta.url).href; // shipped with the app shell
const REMOTE_BASE = null; // set to the CDN base (e.g. "https://content.kairos.example/v1/") to enable OTA updates
const LS_MANIFEST = "kairos.manifest.v1";
const CACHE_NAME = "kairos-content-v1";

export class ContentStore {
  #manifest = null;
  #searchIndex = null;
  #sections = null;
  #weightZones = null;
  #tiers = null;
  #moduleCache = new Map();

  async init() {
    // 1. Always load what we can from the bundled/cached copy first.
    [this.#manifest, this.#searchIndex, this.#sections, this.#weightZones, this.#tiers] =
      await Promise.all([
        this.#getJSON("manifest.json"),
        this.#getJSON("search-index.json"),
        this.#getJSON("config/sections.json"),
        this.#getJSON("config/weight-zones.json"),
        this.#getJSON("config/tiers.json"),
      ]);
    // 2. Kick the update check without blocking startup.
    this.#checkForUpdates().catch((e) => console.info("[content] update check skipped:", e.message));
    return this;
  }

  get sections() { return this.#sections.sections; }
  get searchEntries() { return this.#searchIndex.entries; }
  get weightZones() { return this.#weightZones; }
  get tiers() { return this.#tiers.tiers; }
  get manifest() { return this.#manifest; }

  entryByRoute(route) {
    return this.searchEntries.find((e) => e.route === route) || null;
  }

  /** Load a module by its manifest key (e.g. "calculators/cardiovascular/heart-score"). */
  async module(key) {
    if (this.#moduleCache.has(key)) return this.#moduleCache.get(key);
    const meta = this.#manifest.modules[key];
    if (!meta) throw new Error(`no module "${key}" in manifest`);
    const json = await this.#getJSON(meta.path);
    this.#moduleCache.set(key, json);
    return json;
  }

  async moduleByRoute(route) {
    const entry = this.entryByRoute(route);
    if (!entry) throw new Error(`no content at route "${route}"`);
    const key = Object.keys(this.#manifest.modules).find(
      (k) => this.#manifest.modules[k].path.endsWith(`/${entry.id}.json`)
    );
    return this.module(key);
  }

  // --- internals ---------------------------------------------------------

  async #getJSON(relPath) {
    // Try the runtime cache (updated OTA), then the bundled shell copy.
    if ("caches" in self) {
      try {
        const cache = await caches.open(CACHE_NAME);
        const hit = await cache.match(new URL(relPath, REMOTE_BASE || BUNDLED_BASE).href);
        if (hit) return hit.json();
      } catch { /* private mode / unsupported — fall through */ }
    }
    const res = await fetch(new URL(relPath, BUNDLED_BASE).href, { cache: "no-cache" });
    if (!res.ok) throw new Error(`${relPath}: ${res.status}`);
    return res.json();
  }

  async #checkForUpdates() {
    if (!REMOTE_BASE || !navigator.onLine) return;
    const res = await fetch(new URL("manifest.json", REMOTE_BASE).href, { cache: "no-store" });
    if (!res.ok) return;
    const remote = await res.json();
    const cachedVersions = JSON.parse(localStorage.getItem(LS_MANIFEST) || "{}");
    const cache = await caches.open(CACHE_NAME);

    const changed = Object.entries(remote.modules).filter(
      ([key, m]) => (cachedVersions[key] ?? 0) < m.content_version
    );
    for (const [key, m] of changed) {
      try {
        const url = new URL(m.path, REMOTE_BASE).href;
        await cache.add(url); // background fetch into the runtime cache
        cachedVersions[key] = m.content_version;
        this.#moduleCache.delete(key); // force re-read on next access
      } catch (e) {
        console.info(`[content] failed to update ${key}:`, e.message);
      }
    }
    if (changed.length) {
      await cache.put(
        new URL("manifest.json", REMOTE_BASE).href,
        new Response(JSON.stringify(remote), { headers: { "content-type": "application/json" } })
      );
      localStorage.setItem(LS_MANIFEST, JSON.stringify(cachedVersions));
      this.#manifest = remote;
      window.dispatchEvent(new CustomEvent("kairos:content-updated", { detail: { changed: changed.map(([k]) => k) } }));
    }
  }
}
