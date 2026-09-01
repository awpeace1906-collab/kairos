import { ContentStore } from "./lib/contentStore.js";
import { createRouter } from "./lib/router.js";
import { renderHome } from "./views/home.js";
import { renderSection } from "./views/section.js";
import { renderContent } from "./views/content.js";
import { renderAbout } from "./views/about.js";
import { el } from "./components.js";

const app = document.getElementById("app");
const store = await new ContentStore().init();

const router = createRouter(async (route) => {
  window.scrollTo(0, 0);
  try {
    if (route === "/" || route === "") {
      app.replaceChildren(renderHome(store, router));
    } else if (route === "/about") {
      app.replaceChildren(el("div", { class: "detail" }, el("a", { href: "#/", class: "back" }, "‹ Home"), renderAbout()));
    } else if (route.startsWith("/section/")) {
      app.replaceChildren(renderSection(route.slice("/section/".length), store));
    } else {
      const mod = await store.moduleByRoute(route);
      app.replaceChildren(
        el("div", { class: "detail" }, el("a", { href: "#/", class: "back" }, "‹ Home"), renderContent(mod, route, store))
      );
    }
  } catch (err) {
    app.replaceChildren(el("section", { class: "content" }, el("h1", {}, "Not found"), el("p", { class: "muted" }, err.message), el("a", { href: "#/" }, "Back to home")));
  }
});

router.start();

window.addEventListener("kairos:content-updated", (e) => {
  console.info("[content] updated:", e.detail.changed);
  router.start(); // silent re-render from the freshened cache
});

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").catch(() => {});
}
