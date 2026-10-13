import type { ChangelogEntry } from "@/lib/changelog";

export function ChangelogFeed({ entries }: { entries: ChangelogEntry[] }) {
  if (entries.length === 0) {
    return (
      <p className="text-sm text-zinc-500 dark:text-zinc-400">Changelog will appear here once CHANGELOG.md is available at build time.</p>
    );
  }

  return (
    <div className="space-y-6">
      {entries.map((entry) => (
        <article
          key={entry.title}
          className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-800 dark:bg-zinc-900/40"
        >
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">{entry.title}</h3>
          <div className="prose prose-zinc mt-3 max-w-none text-sm dark:prose-invert">
            {entry.body.split("\n").map((line, index) => (
              <p key={`${entry.title}-${index}`} className="mb-2 last:mb-0 text-zinc-600 dark:text-zinc-300">{line}</p>
            ))}
          </div>
        </article>
      ))}
    </div>
  );
}
