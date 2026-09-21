/**
 * American English rules for Kairos content and UI copy.
 *
 * The guide ships to a US clinical audience, so British spellings and
 * British (INN) drug names are defects, not style. A 2026-09-16 one-off
 * script normalized the corpus once; newly authored prose immediately
 * reintroduced six spellings, so the rule lives here now and runs in CI.
 *
 * Three deliberate design choices:
 *
 * 1. `-ise`/`-yse` use an EXPLICIT STEM ALLOWLIST rather than a blanket
 *    pattern. English is full of words that are `-ise` in American English
 *    too (advertise, comprise, exercise, expertise, franchise, improvise,
 *    premise, promise, supervise, surprise…), and a blanket rule mangles
 *    them. Adding a stem is cheap; un-mangling a corpus is not.
 *
 * 2. `protectedTerms` wins over every rule. Journal names, society names,
 *    and taxonomy (Haemophilus, Haemophilus influenzae) are proper nouns —
 *    "correcting" a citation makes it unfindable.
 *
 * 3. Drug names are a SEPARATE category from spelling. Turning
 *    paracetamol into acetaminophen is a different kind of edit than
 *    turning colour into color, so the checker reports them under their
 *    own heading and `--fix` handles them the same way but the distinction
 *    stays visible in the report.
 */

/**
 * Tokens that must never be rewritten, in any context.
 *
 * Deliberately SHORT. It only holds strings that cannot legitimately appear
 * in clinical prose — taxonomy and abbreviated journal titles. Everything
 * else that needs protecting (full journal and society names with British
 * spellings) is protected by CONTEXT instead: the checker skips `sources`,
 * `changelog`, and `buildNote`, and skips citation-shaped lines in prose
 * files. Protecting an ordinary word like "Centre" or "Defence" by spelling
 * alone would silently exempt it at the start of every sentence.
 */
export const protectedTerms = [
  "Haemophilus",
  "Haemonetics",
  "Anaesthesiol",
  "Anaesthesiologists",
  "Anaesthetists",
  "Paediatr",
  "Haematol",
  "Haemost",
  "Gynaecol",
  "Orthopaed",
];

/**
 * `-ise` -> `-ize` stems. Each entry is the part BEFORE the suffix, and the
 * rule generates ise/ises/ised/ising/isation/isations for it.
 */
export const izeStems = [
  "alkalin", "anonym", "authors", "cannul", "categor", "catheter", "central",
  "character", "colon", "crystall", "decentral", "deion", "demineral",
  "deodor", "desensit", "destabil", "digit", "emphas", "equal", "familiar",
  "final", "general", "harmon", "hospital", "hybrid", "hyperpolar",
  "immobil", "immun", "individual", "initial", "ion", "legal", "liberal",
  "local", "magnet", "marginal", "maxim", "mechan", "memor", "minim",
  "mineral", "mobil", "modern", "monopol", "moral", "nebul", "neutral",
  "normal", "opson", "optim", "organ", "oxid", "oxygen", "patholog",
  "personal", "polar", "polymer", "popular", "pressur", "priorit",
  "protocol", "pulver", "random", "rational", "real", "recogn", "regional",
  "regular", "rehydrat", "reorgan", "resuscit", "revital", "revolution",
  "sanit", "scrutin", "sensit", "serial", "solubil", "special", "stabil",
  "standard", "steril", "subsid", "summar", "syllab", "symptomat",
  "synchron", "synthes", "systemat", "tranquil", "urban", "util", "vapor",
  "vascular", "visual", "vital", "vocal", "volatil", "vulcan",
];
/**
 * `-yse` -> `-yze` stems, given WITH the `y` (British "analyse", American
 * "analyze"). Note the suffix set below deliberately omits `-es`:
 * "analyses", "dialyses" and "paralyses" are correct American English as
 * noun plurals, so rewriting them to "analyzes" would be a new error.
 */
export const yzeStems = [
  "analy", "cataly", "dialy", "electroly", "haemoly", "hemoly", "hydroly",
  "paraly",
];
/**
 * Literal pairs. Order matters: longer/more specific forms come first so a
 * shorter rule cannot eat a prefix of a longer one.
 */
const literalPairs = [
  // --- ae / oe digraphs (the biggest medical category) ---
  ["anaesthesiologist", "anesthesiologist"],
  ["anaesthesiology", "anesthesiology"],
  ["anaesthetist", "anesthetist"],
  ["anaesthetic", "anesthetic"],
  ["anaesthetise", "anesthetize"],
  ["anaesthetize", "anesthetize"],
  ["anaesthesia", "anesthesia"],
  ["anaemia", "anemia"],
  ["anaemic", "anemic"],
  ["aetiology", "etiology"],
  ["aetiologic", "etiologic"],
  ["apnoea", "apnea"],
  ["apnoeic", "apneic"],
  ["bacteraemia", "bacteremia"],
  ["caesarean", "cesarean"],
  ["caesarian", "cesarean"],
  ["coeliac", "celiac"],
  ["diarrhoea", "diarrhea"],
  ["dyspnoea", "dyspnea"],
  ["dyspnoeic", "dyspneic"],
  ["faeces", "feces"],
  ["faecal", "fecal"],
  ["foetal", "fetal"],
  ["foetus", "fetus"],
  ["gynaecolog", "gynecolog"],
  ["haemangioma", "hemangioma"],
  ["haematocrit", "hematocrit"],
  ["haematolog", "hematolog"],
  ["haematoma", "hematoma"],
  ["haematuria", "hematuria"],
  ["haemodynamic", "hemodynamic"],
  ["haemodialysis", "hemodialysis"],
  ["haemofiltration", "hemofiltration"],
  ["haemoglobin", "hemoglobin"],
  ["haemolysis", "hemolysis"],
  ["haemolytic", "hemolytic"],
  ["haemoptysis", "hemoptysis"],
  ["haemorrhage", "hemorrhage"],
  ["haemorrhagic", "hemorrhagic"],
  ["haemorrhoid", "hemorrhoid"],
  ["haemostasis", "hemostasis"],
  ["haemostatic", "hemostatic"],
  ["haemothorax", "hemothorax"],
  ["hypercapnoea", "hypercapnia"],
  ["hyperkalaemia", "hyperkalemia"],
  ["hypernatraemia", "hypernatremia"],
  ["hypocalcaemia", "hypocalcemia"],
  ["hypoglycaemia", "hypoglycemia"],
  ["hypokalaemia", "hypokalemia"],
  ["hyponatraemia", "hyponatremia"],
  ["hypoxaemia", "hypoxemia"],
  ["hypoxaemic", "hypoxemic"],
  ["ischaemia", "ischemia"],
  ["ischaemic", "ischemic"],
  ["leucocyte", "leukocyte"],
  ["leucocytosis", "leukocytosis"],
  ["leukaemia", "leukemia"],
  ["oedema", "edema"],
  ["oedematous", "edematous"],
  ["oesophag", "esophag"],
  ["oestrogen", "estrogen"],
  ["orthopaedic", "orthopedic"],
  ["paediatric", "pediatric"],
  ["paediatrician", "pediatrician"],
  ["paracentesis", "paracentesis"],
  ["septicaemia", "septicemia"],
  ["tachypnoea", "tachypnea"],
  ["tachypnoeic", "tachypneic"],
  ["uraemia", "uremia"],
  ["uraemic", "uremic"],
  ["normocapnoea", "normocapnia"],
  ["hypocapnoea", "hypocapnia"],
  ["hypercalcaemia", "hypercalcemia"],
  ["hyperglycaemia", "hyperglycemia"],
  ["hypermagnesaemia", "hypermagnesemia"],
  ["hypomagnesaemia", "hypomagnesemia"],
  ["hyperphosphataemia", "hyperphosphatemia"],
  ["hypophosphataemia", "hypophosphatemia"],
  ["hypoalbuminaemia", "hypoalbuminemia"],
  ["hyperammonaemia", "hyperammonemia"],
  ["acidaemia", "acidemia"],
  ["alkalaemia", "alkalemia"],
  ["toxaemia", "toxemia"],
  ["viraemia", "viremia"],
  ["fungaemia", "fungemia"],
  ["paraesthesia", "paresthesia"],
  ["anaphylactoid", "anaphylactoid"],
  ["haemoperitoneum", "hemoperitoneum"],
  ["haemopericardium", "hemopericardium"],

  // --- -our -> -or ---
  ["behaviour", "behavior"],
  ["colour", "color"],
  ["endeavour", "endeavor"],
  ["favour", "favor"],
  ["favourite", "favorite"],
  ["flavour", "flavor"],
  ["harbour", "harbor"],
  ["honour", "honor"],
  ["humour", "humor"],
  ["labour", "labor"],
  ["neighbour", "neighbor"],
  ["odour", "odor"],
  ["rigour", "rigor"],
  ["rumour", "rumor"],
  ["tumour", "tumor"],
  ["valour", "valor"],
  ["vapour", "vapor"],
  ["vigour", "vigor"],
  ["armour", "armor"],
  ["parlour", "parlor"],
  ["saviour", "savior"],
  ["savour", "savor"],

  // --- -re -> -er ---
  ["centre", "center"],
  ["calibre", "caliber"],
  ["fibre", "fiber"],
  ["litre", "liter"],
  ["millilitre", "milliliter"],
  ["microlitre", "microliter"],
  ["decilitre", "deciliter"],
  ["metre", "meter"],
  ["centimetre", "centimeter"],
  ["millimetre", "millimeter"],
  ["micrometre", "micrometer"],
  ["kilometre", "kilometer"],
  ["manoeuvre", "maneuver"],
  ["manoeuvring", "maneuvering"],
  ["manoeuvred", "maneuvered"],
  ["goitre", "goiter"],
  ["lustre", "luster"],
  ["sabre", "saber"],
  ["sombre", "somber"],
  ["spectre", "specter"],
  ["theatre", "theater"],

  // --- -ce -> -se ---
  ["defence", "defense"],
  ["offence", "offense"],
  ["pretence", "pretense"],

  // --- doubled / single L ---
  ["cancelled", "canceled"],
  ["cancelling", "canceling"],
  ["counselling", "counseling"],
  ["counsellor", "counselor"],
  ["enrol", "enroll"],
  ["enrolment", "enrollment"],
  ["fuelled", "fueled"],
  ["fulfil", "fulfill"],
  ["fulfilment", "fulfillment"],
  ["instalment", "installment"],
  ["labelled", "labeled"],
  ["labelling", "labeling"],
  ["levelled", "leveled"],
  ["marvellous", "marvelous"],
  ["modelled", "modeled"],
  ["modelling", "modeling"],
  ["signalling", "signaling"],
  ["skilful", "skillful"],
  ["totalled", "totaled"],
  ["totalling", "totaling"],
  ["travelled", "traveled"],
  ["travelling", "traveling"],
  ["wilful", "willful"],

  // --- miscellaneous ---
  ["ageing", "aging"],
  ["aluminium", "aluminum"],
  ["amongst", "among"],
  ["cheque", "check"],
  ["draught", "draft"],
  ["grey", "gray"],
  ["jewellery", "jewelry"],
  ["judgement", "judgment"],
  ["kerb", "curb"],
  ["mould", "mold"],
  ["moult", "molt"],
  ["plough", "plow"],
  ["programme", "program"],
  ["smoulder", "smolder"],
  ["storey", "story"],
  ["sulphate", "sulfate"],
  ["sulphide", "sulfide"],
  ["sulphonamide", "sulfonamide"],
  ["sulphur", "sulfur"],
  ["tyre", "tire"],
  ["whilst", "while"],
];

/**
 * British (INN) drug and nomenclature names -> the USAN/US name a US
 * clinician will actually see on a vial or an order screen. Reported
 * separately from spelling because it is a different kind of edit.
 */
const drugPairs = [
  ["adrenaline", "epinephrine"],
  ["noradrenaline", "norepinephrine"],
  ["paracetamol", "acetaminophen"],
  ["salbutamol", "albuterol"],
  ["frusemide", "furosemide"],
  ["lignocaine", "lidocaine"],
  ["pethidine", "meperidine"],
  ["thiopentone", "thiopental"],
  ["suxamethonium", "succinylcholine"],
  ["chlorphenamine", "chlorpheniramine"],
  ["glyceryl trinitrate", "nitroglycerin"],
  ["amethocaine", "tetracaine"],
  ["ciclosporin", "cyclosporine"],
  ["rifampicin", "rifampin"],
  ["phenytoin sodium BP", "phenytoin"],
  ["hyoscine", "scopolamine"],
  ["prilocaine", "prilocaine"],
  ["oxpentifylline", "pentoxifylline"],
  ["dexamfetamine", "dextroamphetamine"],
  ["beclometasone", "beclomethasone"],
  ["bendroflumethiazide", "bendroflumethiazide"],
  ["colecalciferol", "cholecalciferol"],
  ["dosulepin", "doxepin"],
  ["isoprenaline", "isoproterenol"],
  ["lidocaine hydrochloride BP", "lidocaine"],
  ["methylthioninium chloride", "methylene blue"],
  ["mercaptamine", "cysteamine"],
  ["moxonidine", "moxonidine"],
  ["oestradiol", "estradiol"],
  ["phenobarbitone", "phenobarbital"],
  ["procaine penicillin", "penicillin G procaine"],
  ["sodium valproate", "valproate sodium"],
  ["trimethoprim-sulphamethoxazole", "trimethoprim-sulfamethoxazole"],
  ["sulphamethoxazole", "sulfamethoxazole"],
  ["sulphasalazine", "sulfasalazine"],
  ["cephalexin", "cephalexin"],
  ["cefalexin", "cephalexin"],
  ["cefuroxime axetil", "cefuroxime axetil"],
  ["amoxycillin", "amoxicillin"],
  ["indometacin", "indomethacin"],
  ["glibenclamide", "glyburide"],
  ["metoclopramide hydrochloride BP", "metoclopramide"],
];

/**
 * Digraph rules that must match INSIDE a word, not just at its start —
 * "methaemoglobinaemia", "normokalaemia", "orthopaedic" all need fixing and
 * none of them begin with the British fragment.
 *
 * These stay deliberately narrow. A bare `oe` -> `e` rule would wreck
 * "does", "coexist", "phoenix" and "poem"; a bare `ae` -> `e` rule would
 * wreck "aerobic" and "maelstrom". So each entry carries enough context to
 * be unambiguous, and `-pnoea` is spelled out rather than reached via `oe`.
 */
const substringPairs = [
  ["aem", "em"],          // haemo-, anaemia, hyperkalaemia, methaemoglobin
  ["aesthe", "esthe"],
  ["aetiol", "etiol"],
  ["paed", "ped"],        // paediatric, orthopaedic, encyclopaedia
  ["gynaec", "gynec"],
  ["caesar", "cesar"],
  ["oedem", "edem"],
  ["oesophag", "esophag"],
  ["oestro", "estro"],
  ["oestra", "estra"],
  ["coeliac", "celiac"],
  ["foet", "fet"],
  ["faec", "fec"],
  ["amoeb", "ameb"],
  ["diarrhoe", "diarrhe"],
  ["gonorrhoe", "gonorrhe"],
  ["leucocyt", "leukocyt"],
  ["leucopen", "leukopen"],
  ["pnoea", "pnea"],
  ["pnoeic", "pneic"],
  ["ischaem", "ischem"],
];

/** Escape a literal for use inside a RegExp. */
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/** Match `replacement`'s case to `found`'s (lower / Title / UPPER). */
export function matchCase(found, replacement) {
  if (found === found.toUpperCase() && /[A-Z]{2,}/.test(found)) {
    return replacement.toUpperCase();
  }
  if (found[0] === found[0].toUpperCase()) {
    return replacement[0].toUpperCase() + replacement.slice(1);
  }
  return replacement;
}

function buildRules() {
  const rules = [];

  /**
   * Where the British form is a PREFIX of the American one ("enrol" inside
   * "enroll"), the naive pattern re-fires on already-correct text and the
   * doubled letter compounds on every pass: enrollment -> enrolllment ->
   * enrollllment. A negative lookahead for the next American character
   * makes the rule idempotent — it still fixes "enrolment" but leaves
   * "enrollment" alone.
   */
  const pairRule = (from, to, category) => {
    const guardChar = to.toLowerCase().startsWith(from.toLowerCase())
      ? to[from.length]
      : null;
    const lookahead = guardChar ? `(?!${esc(guardChar)})` : "";
    return {
      category,
      re: new RegExp(`\\b${esc(from)}${lookahead}([a-z]*)\\b`, "gi"),
      apply: (m, tail) => matchCase(m, to) + tail,
      note: `${from} -> ${to}`,
    };
  };

  for (const [from, to] of literalPairs) {
    if (from === to) continue;
    rules.push(pairRule(from, to, "spelling"));
  }

  for (const stem of [...new Set(izeStems)]) {
    rules.push({
      category: "spelling",
      re: new RegExp(`\\b(${esc(stem)})is(e|es|ed|ing|ation|ations)\\b`, "gi"),
      apply: (m, s, suf) => `${s}iz${suf}`,
      note: `${stem}ise -> ${stem}ize`,
    });
  }

  for (const stem of [...new Set(yzeStems)]) {
    rules.push({
      category: "spelling",
      re: new RegExp(`\\b(${esc(stem)})s(e|ed|ing)\\b`, "gi"),
      apply: (m, s, suf) => `${s}z${suf}`,
      note: `${stem}se -> ${stem}ze`,
    });
  }

  for (const [from, to] of substringPairs) {
    rules.push({
      category: "spelling",
      re: new RegExp(esc(from), "gi"),
      // A substring carries no word case of its own, so only the first
      // character's case is preserved (matters for "Haemorrhage" at the
      // start of a sentence; irrelevant mid-word).
      apply: (m) =>
        m[0] === m[0].toUpperCase() && m[0] !== m[0].toLowerCase()
          ? to[0].toUpperCase() + to.slice(1)
          : to,
      note: `${from} -> ${to}`,
    });
  }

  for (const [from, to] of drugPairs) {
    if (from === to) continue;
    rules.push(pairRule(from, to, "drug-name"));
  }

  return rules;
}

export const rules = buildRules();

const protectedRe = new RegExp(
  `\\b(${protectedTerms
    .slice()
    .sort((a, b) => b.length - a.length)
    .map(esc)
    .join("|")})\\b`,
  "g",
);

/** Character ranges in `text` covered by a protected proper noun. */
function protectedRanges(text) {
  const out = [];
  for (const m of text.matchAll(protectedRe)) {
    out.push([m.index, m.index + m[0].length]);
  }
  return out;
}

const inRange = (ranges, start, end) =>
  ranges.some(([a, b]) => start < b && a < end);

/**
 * Find every British spelling / INN drug name in `text`.
 *
 * Rules overlap by design — "haemolysed" is matched by the `-yse` stem rule
 * AND by the `aem` digraph rule — so candidates are collected first and then
 * selected greedily, longest-match-wins at each position. Applying
 * overlapping matches blindly duplicates text ("Haemolyzedemolysed").
 *
 * Returns `[{ match, suggestion, category, note, index }]`, non-overlapping
 * and ordered by position.
 */
export function findIssues(text, { categories = ["spelling", "drug-name"] } = {}) {
  if (typeof text !== "string" || !text) return [];
  const guard = protectedRanges(text);
  const candidates = [];

  rules.forEach((rule, priority) => {
    if (!categories.includes(rule.category)) return;
    rule.re.lastIndex = 0;
    for (const m of text.matchAll(rule.re)) {
      const start = m.index;
      const end = start + m[0].length;
      if (inRange(guard, start, end)) continue;
      candidates.push({
        match: m[0],
        suggestion: rule.apply(...m),
        category: rule.category,
        note: rule.note,
        index: start,
        end,
        priority,
      });
    }
  });

  candidates.sort(
    (a, b) =>
      a.index - b.index ||
      b.match.length - a.match.length ||
      a.priority - b.priority,
  );

  const out = [];
  let taken = 0;
  for (const c of candidates) {
    if (c.index < taken) continue;
    if (c.suggestion === c.match) continue;
    out.push(c);
    taken = c.end;
  }
  return out;
}

/**
 * Rewrite `text` to American English, leaving protected proper nouns alone.
 *
 * Iterates to a fixed point: "haemolysed" needs two passes (the `-yse` rule
 * gives "haemolyzed", then the `aem` rule gives "hemolyzed").
 */
export function fixText(text, { categories = ["spelling", "drug-name"] } = {}) {
  let current = text;
  for (let pass = 0; pass < 5; pass += 1) {
    const issues = findIssues(current, { categories });
    if (!issues.length) return current;
    let next = "";
    let cursor = 0;
    for (const i of issues) {
      next += current.slice(cursor, i.index) + i.suggestion;
      cursor = i.index + i.match.length;
    }
    next += current.slice(cursor);
    if (next === current) return current;
    current = next;
  }
  return current;
}
