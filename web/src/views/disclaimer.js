import { el } from "../components.js";

export function renderDisclaimer() {
  return el(
    "section",
    { class: "content prose about" },
    el("h1", {}, "Medical & Legal Disclaimer"),
    el(
      "p",
      { class: "disclaimer" },
      "Kairos is a clinical reference and calculation aid for licensed healthcare professionals. It is provided for informational and educational purposes only and does not constitute medical advice. It does not replace clinical judgment, your institution's protocols, a medication's package insert / prescribing information, or consultation with a qualified clinician or pharmacist. Independently verify every dose, threshold, and recommendation — especially in high-acuity, pediatric, renal/hepatic-impairment, or pregnancy contexts — before acting on it. Content is checked against the sources listed on each page as of its last-verified date, but medicine changes; a citation does not guarantee the information is current. The authors and maintainers of Kairos assume no liability for clinical outcomes resulting from its use."
    )
  );
}
