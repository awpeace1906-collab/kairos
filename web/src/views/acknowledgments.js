import { el } from "../components.js";

export function renderAcknowledgments() {
  return el(
    "section",
    { class: "content prose about" },
    el("h1", {}, "Acknowledgments"),
    el("h2", {}, "Typography"),
    el("p", { class: "muted" }, "IBM Plex Sans and IBM Plex Mono, © IBM Corporation, licensed under the SIL Open Font License 1.1."),
    el("h2", {}, "Anatomical illustrations"),
    el(
      "p",
      { class: "muted" },
      "Several procedure figures are drawn over plates from Henry Gray\u2019s ",
      el("em", {}, "Anatomy of the Human Body"),
      " (20th edition, 1918, revised by Warren H. Lewis), illustrated by Henry Vandyke Carter and made freely available through Bartleby.com and Wikimedia Commons. The plates are in the public domain, and we credit them anyway, with gratitude: more than 160 years after Carter first drew them, they are still teaching people where to put the needle."
    ),
    el("h2", {}, "Companion apps"),
    el("p", { class: "muted" }, "Kairos is built alongside AnesCalc (anesthesia calculators), CRISIS (crisis protocols & envenomation), and TEE Compass — with a POCUS guide in the works — focused tools rather than one app that tries to do everything.")
  );
}
