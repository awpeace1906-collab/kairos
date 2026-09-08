// App-level constants that are not clinical content. Keep the GitHub repo slug
// here (one place) so the "Flag as outdated" links in both clients point at the
// same issue tracker. Mirror any change in ios/Sources/App/AppConfig.swift.

export const GITHUB_REPO = "awpeace1906-collab/kairos";

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
