// Offline-first service worker. Precache the app shell + the bundled content tree
// so a first launch with no connectivity still works (Content Update Architecture
// spec, fallback #4). OTA content updates land in a separate runtime cache managed
// by ContentStore; this SW just guarantees the shell and the bundled baseline.

const SHELL_CACHE = "kairos-shell-v1";
const SHELL = [
  "./",
  "./index.html",
  "./styles.css",
  "./manifest.webmanifest",
  "./src/main.js",
  "./src/components.js",
  "./src/lib/contentStore.js",
  "./src/lib/router.js",
  "./src/lib/search.js",
  "./src/lib/expr.js",
  "./src/lib/calcEngine.js",
  "./src/lib/weightZones.js",
  "./src/lib/session.js",
  "./src/views/home.js",
  "./src/views/section.js",
  "./src/views/content.js",
  "./src/views/calculator.js",
  "./src/views/about.js",
  "./content/manifest.json",
  "./content/search-index.json",
  "./content/config/sections.json",
  "./content/config/weight-zones.json",
  "./content/config/tiers.json",
];

self.addEventListener("install", (e) => {
  e.waitUntil(
    caches.open(SHELL_CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== SHELL_CACHE && !k.startsWith("kairos-content")).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const { request } = e;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== location.origin) return;

  // Content JSON: cache-first, refresh in the background (stale-while-revalidate).
  if (url.pathname.includes("/content/")) {
    e.respondWith(
      caches.open(SHELL_CACHE).then(async (cache) => {
        const cached = await cache.match(request);
        const network = fetch(request)
          .then((res) => {
            if (res.ok) cache.put(request, res.clone());
            return res;
          })
          .catch(() => cached);
        return cached || network;
      })
    );
    return;
  }

  // App shell: cache-first, fall back to network.
  e.respondWith(caches.match(request).then((c) => c || fetch(request)));
});
