// App-level constants that are not clinical content. Keep the GitHub repo slug
// here (one place) so the "Flag as outdated" links in both clients point at the
// same issue tracker. Mirror any change in ios/Sources/App/AppConfig.swift.

export const GITHUB_REPO = "awpeace1906-collab/kairos";

/** "0.1.0" — the single place to bump the web client's version. Keep in sync
    with MARKETING_VERSION in ios/project.yml (the two platforms build/ship
    independently, so this can't be derived automatically the way the iOS
    About screen reads it from its own bundle — bump both when releasing). */
export const APP_VERSION = "0.1.0";

/** Build a prefilled "content outdated" GitHub issue URL for a module's meta. */
export function flagOutdatedURL(mod) {
  const title = `Outdated: ${mod.title} (${mod.id} v${mod.content_version ?? "?"})`;
  const body = [
    `**Module:** ${mod.id} (${mod.contentType ?? "?"})`,
    `**Version:** v${mod.content_version ?? "?"}`,
    `**Last verified:** ${mod.last_reviewed ?? "—"}`,
    `**Next review due:** ${mod.next_review_due ?? "—"}`,
    `**Review tier:** ${mod.review_tier ?? "—"}`,
    `**Client:** web · ${navigator.userAgent}`,
    ``,
    `**What's outdated / newer source:**`,
    ``,
  ].join("\n");
  const q = new URLSearchParams({ labels: "content,needs-review", title, body });
  return `https://github.com/${GITHUB_REPO}/issues/new?${q.toString()}`;
}

/** General "report an issue" link for the Settings screen — no module context. */
export function newIssueURL() {
  return `https://github.com/${GITHUB_REPO}/issues/new`;
}
