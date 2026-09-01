// Hash router. The hash IS the content `route` from the search index
// (e.g. #/calculators/cardiovascular/heart-score), so a search result links
// straight to its item — Search_TOC_Design_Spec.md.

export function createRouter(onRoute) {
  function current() {
    return decodeURIComponent(location.hash.replace(/^#/, "")) || "/";
  }
  function go(path) {
    if (current() === path) onRoute(path);
    else location.hash = path;
  }
  window.addEventListener("hashchange", () => onRoute(current()));
  return { current, go, start: () => onRoute(current()) };
}
