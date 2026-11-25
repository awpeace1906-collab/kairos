# UTICalc Link Card — Build Instructions for Kairos (content v1.0.0)

## What this is
A Peds Module reference card that explains UTICalc and links out to https://uticalc.pitt.edu/. **It is not a calculator.** UTICalc is licensed by the University of Pittsburgh for non-commercial education and research only, so Kairos must not implement, embed, or approximate its model.

## Rules
1. All text comes from `uticalc-card.json`. Do not reword, add, or remove clinical content.
2. No inputs, no scoring, no probability output, no WebView/iframe of the Pitt site. The link opens in the external browser (SFSafariViewController or the system browser is fine; no in-app embedding of their form).
3. Keep the attribution line visible on the card.
4. If the JSON doesn't map cleanly onto the existing Peds/Reference Library card schema, list the mismatches and stop.

## Layout
Use the standard Reference Library template: header (title, subtitle, "External tool" badge) → **Why This Matters** → sections in JSON order → **Open UTICalc** button → **Clinical Takeaway** card → attribution → citations.
- Show `link.offline_text` in place of the button when the device is offline.
- Lens: ED. Add the `search_keywords` to the home search/TOC index.

## Acceptance
- [ ] Card renders in the Peds Module and appears in search for "UTI", "UTICalc", and "febrile infant".
- [ ] Button opens https://uticalc.pitt.edu/ outside the app; offline text shows with no connection.
- [ ] No UTICalc logic, coefficients, or input fields exist anywhere in the codebase.

## Report back
Where the card lives, how it maps to the existing schema, screenshots (online and offline), and any mismatches you stopped on.
