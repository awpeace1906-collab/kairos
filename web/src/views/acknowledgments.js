import { el } from "../components.js";

export function renderAcknowledgments() {
  return el(
    "section",
    { class: "content prose about" },
    el("h1", {}, "Acknowledgments"),
    el("h2", {}, "Typography"),
    el("p", { class: "muted" }, "IBM Plex Sans and IBM Plex Mono, © IBM Corporation, licensed under the SIL Open Font License 1.1."),
    el("h2", {}, "Companion apps"),
    el("p", { class: "muted" }, "Kairos is built alongside AnesCalc (anesthesia calculators) and CRISIS (crisis protocols & envenomation) — three focused tools rather than one that tries to do everything.")
  );
}
