import { ContentStore } from "./lib/contentStore.js";
import { createRouter } from "./lib/router.js";
import { renderHome } from "./views/home.js";
import { renderSection } from "./views/section.js";
import { renderContent } from "./views/content.js";
import { renderSettings } from "./views/settings.js";
import { renderAbout } from "./views/about.js";
import { renderDisclaimer } from "./views/disclaimer.js";
import { renderAcknowledgments } from "./views/acknowledgments.js";
import { renderSources } from "./views/sources.js";
import { el, pinButton } from "./components.js";
import { applyTheme } from "./lib/prefs.js";

const app = document.getElementById("app");
const rail = document.getElementById("nav-rail");
const tabBar = document.getElementById("tab-bar");
const store = await new ContentStore().init();

applyTheme();
buildRail();
buildTabBar();

const router = createRouter(async (route) => {
  window.scrollTo(0, 0);
  try {
    if (route === "/" || route === "") {
      app.replaceChildren(renderHome(store, router));
    } else if (route === "/about") {
      app.replaceChildren(el("div", { class: "detail" }, el("a", { href: "#/", class: "back" }, "‹ Home"), renderSettings(store)));
    } else if (route === "/about/info") {
      app.replaceChildren(el("div", { class: "detail" }, el("a", { href: "#/about", class: "back" }, "‹ Settings"), renderAbout()));
    } else if (route === "/about/disclaimer") {
      app.replaceChildren(el("div", { class: "detail" }, el("a", { href: "#/about", class: "back" }, "‹ Settings"), renderDisclaimer()));
    } else if (route === "/about/acknowledgments") {
      app.replaceChildren(el("div", { class: "detail" }, el("a", { href: "#/about", class: "back" }, "‹ Settings"), renderAcknowledgments()));
    } else if (route === "/sources") {
      app.replaceChildren(el("div", { class: "detail" }, el("a", { href: "#/", class: "back" }, "‹ Home"), renderSources(store)));
    } else if (route.startsWith("/section/")) {
      app.replaceChildren(renderSection(route.slice("/section/".length), store));
    } else {
      const mod = await store.moduleByRoute(route);
      app.replaceChildren(
        el(
          "div",
          { class: "detail" },
          el(
            "div",
            { class: "detail-bar" },
            el("a", { href: "#/", class: "back" }, "‹ Home"),
            pinButton(mod, store)
          ),
          renderContent(mod, route, store)
        )
      );
    }
  } catch (err) {
    app.replaceChildren(el("section", { class: "content" }, el("h1", {}, "Not found"), el("p", { class: "muted" }, err.message), el("a", { href: "#/" }, "Back to home")));
  }
  markRail(route);
  markTabBar(route);
});

router.start();

/* Persistent left nav rail — visible only at desktop widths (CSS). It is the
   primary section switcher there; the home view hides its own section list when
   the rail is showing, so there's still just one list. */
function buildRail() {
  rail.replaceChildren(
    el("a", { class: "rail-brand", href: "#/" }, "Kairos", el("i", { "aria-hidden": "true" })),
    el(
      "nav",
      { class: "rail-nav" },
      store.sections.map((s) =>
        el(
          "a",
          { class: "rail-link", href: `#/section/${s.id}`, "data-route": `/section/${s.id}` },
          el("span", { class: "rail-mark", "data-section": s.id, "aria-hidden": "true" }),
          el("span", { class: "rail-label" }, s.title)
        )
      )
    ),
    el(
      "div",
      { class: "rail-foot" },
      el("a", { href: "#/about", "data-route": "/about" }, "Settings"),
      el("span", {}, " · "),
      el("a", { href: "#/sources", "data-route": "/sources" }, "Sources")
    )
  );
  rail.hidden = false;
}

/* Bottom tab bar — the mobile-width counterpart to the nav rail (CSS shows
   exactly one of the two, same breakpoint). Three destinations, same as the
   iOS TabView: Home, Sources, Settings (which is where the About page lives). */
function buildTabBar() {
  tabBar.replaceChildren(
    el(
      "a",
      { class: "tab-item", href: "#/", "data-route": "/" },
      el("span", { class: "tab-icon", "aria-hidden": "true" }, "⌂"),
      el("span", { class: "tab-label" }, "Home")
    ),
    el(
      "a",
      { class: "tab-item", href: "#/sources", "data-route": "/sources" },
      el("span", { class: "tab-icon", "aria-hidden": "true" }, "▤"),
      el("span", { class: "tab-label" }, "Sources")
    ),
    el(
      "a",
      { class: "tab-item", href: "#/about", "data-route": "/about" },
      el("span", { class: "tab-icon", "aria-hidden": "true" }, "⚙"),
      el("span", { class: "tab-label" }, "Settings")
    )
  );
  tabBar.hidden = false;
}

function markTabBar(route) {
  const active =
    route === "/" || route === ""
      ? "/"
      : route === "/sources"
      ? route
      : route.startsWith("/about")
      ? "/about"
      : "/"; // any content/section page still belongs under the Home tab
  for (const a of tabBar.querySelectorAll("[data-route]")) {
    a.classList.toggle("active", a.getAttribute("data-route") === active);
  }
}

function markRail(route) {
  for (const a of rail.querySelectorAll("[data-route]")) {
    const r = a.getAttribute("data-route");
    a.classList.toggle("active", route === r || (r === "/about" && route.startsWith("/about")));
  }
  // a content page belongs to its section — light that rail row too
  const entry = route.startsWith("/section/") ? null : store.entryByRoute(route);
  if (entry) {
    const sec = store.sections.find((s) => s.title === entry.section);
    if (sec) rail.querySelector(`[data-route="/section/${sec.id}"]`)?.classList.add("active");
  }
}

window.addEventListener("kairos:content-updated", (e) => {
  console.info("[content] updated:", e.detail.changed);
  buildRail();
  router.start(); // silent re-render from the freshened cache
});

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").catch(() => {});
}
