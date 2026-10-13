import { ChangelogFeed } from "@/components/changelog-feed";
import { EvalResultsTable } from "@/components/eval-results-table";
import { TestFlightCTA } from "@/components/testflight-cta";
import { loadChangelog } from "@/lib/changelog";
import { PRODUCT_NAME, PRODUCT_TAGLINE } from "@/lib/constants";
import { loadEvalResults } from "@/lib/eval-results";

const steps = [
  {
    title: "Capture",
    description:
      "Save text, links, and screenshots from the app or Share sheet. Everything is stored on your iPhone first—enrichment can fail without losing the capture.",
  },
  {
    title: "Kontext proposes",
    description:
      "On-device models and deterministic extractors suggest calendar events, reminders, and read-later follow-ups. Nothing is written to Calendar or Reminders until you say so.",
  },
  {
    title: "You approve",
    description:
      "Review each suggestion, edit details, and approve into Apple Calendar or Reminders. Permissions are requested only when you tap approve.",
  },
];

export default async function Home() {
  const evalData = await loadEvalResults();
  const changelog = await loadChangelog();

  return (
    <div className="hero-glow">
      <main className="mx-auto max-w-6xl px-6 pb-24">
        <section className="py-16 sm:py-24">
          <p className="mb-4 inline-flex rounded-full border border-sky-200 bg-sky-50 px-3 py-1 text-xs font-medium text-sky-800 dark:border-sky-900 dark:bg-sky-950/50 dark:text-sky-200">
            iPhone · on-device · no cloud account
          </p>
          <h1 className="max-w-3xl text-4xl font-semibold tracking-tight text-zinc-900 sm:text-6xl dark:text-zinc-50">
            {PRODUCT_NAME} turns captures into calendar actions you control.
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-zinc-600 dark:text-zinc-300">{PRODUCT_TAGLINE}</p>
          <div className="mt-10 flex flex-wrap items-center gap-4">
            <TestFlightCTA />
            <a
              href="#how-it-works"
              className="text-sm font-medium text-zinc-600 underline-offset-4 hover:underline dark:text-zinc-300"
            >
              See how it works
            </a>
          </div>
          <div
            className="mt-14 flex aspect-video w-full max-w-4xl items-center justify-center rounded-2xl border border-dashed border-zinc-300 bg-zinc-100/80 text-center dark:border-zinc-700 dark:bg-zinc-900/50"
            aria-label="Product demo placeholder"
          >
            <div className="px-6">
              <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Demo GIF / video</p>
              <p className="mt-1 text-xs text-zinc-400 dark:text-zinc-500">Drop assets here when ready</p>
            </div>
          </div>
        </section>

        <section id="how-it-works" className="scroll-mt-24 py-16">
          <h2 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">Capture, it proposes, you approve</h2>
          <p className="mt-3 max-w-2xl text-zinc-600 dark:text-zinc-300">
            {PRODUCT_NAME} is not a task manager. It proposes actions; Apple&apos;s apps hold the truth after you approve.
          </p>
          <ol className="mt-10 grid gap-6 sm:grid-cols-3">
            {steps.map((step, index) => (
              <li
                key={step.title}
                className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-800 dark:bg-zinc-900/40"
              >
                <span className="text-xs font-semibold uppercase tracking-wide text-sky-600 dark:text-sky-400">
                  Step {index + 1}
                </span>
                <h3 className="mt-2 text-lg font-semibold text-zinc-900 dark:text-zinc-50">{step.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-zinc-600 dark:text-zinc-300">{step.description}</p>
              </li>
            ))}
          </ol>
        </section>

        <section className="py-16">
          <h2 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">Privacy by design</h2>
          <div className="mt-8 grid gap-6 sm:grid-cols-2">
            <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900/40">
              <h3 className="font-semibold text-zinc-900 dark:text-zinc-50">On your phone</h3>
              <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
                Captures, embeddings, and proposed actions stay in local SwiftData. {PRODUCT_NAME} has no account, backend, or analytics SDK.
              </p>
            </div>
            <div className="rounded-2xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900/40">
              <h3 className="font-semibold text-zinc-900 dark:text-zinc-50">Write-only calendar access</h3>
              <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
                Calendar and Reminders permissions are requested only when you approve a suggestion. We do not read your existing calendars to browse events.
              </p>
            </div>
          </div>
          <p className="mt-6 text-sm">
            <a href="/privacy" className="font-medium text-sky-600 hover:underline dark:text-sky-400">Read the full privacy policy →</a>
          </p>
        </section>

        <section id="evals" className="scroll-mt-24 py-16">
          <h2 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">On-device eval results</h2>
          <p className="mt-3 max-w-2xl text-sm text-zinc-600 dark:text-zinc-300">
            Numbers come from the <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">CaptureEvals</code> target on physical hardware.
            Targets: precision ≥ 0.85, recall ≥ 0.70, exact date ≥ 0.85, search R@5 ≥ 0.85, extraction p95 &lt; 3s.
          </p>
          <div className="mt-8">
            <EvalResultsTable data={evalData} />
          </div>
        </section>

        <section className="py-16">
          <h2 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">Changelog</h2>
          <p className="mt-3 text-sm text-zinc-600 dark:text-zinc-300">Shipped milestones for the Kontext capture-to-act stack.</p>
          <div className="mt-8">
            <ChangelogFeed entries={changelog} />
          </div>
        </section>

        <footer className="border-t border-zinc-200 pt-10 text-sm text-zinc-500 dark:border-zinc-800 dark:text-zinc-400">
          <p>© {new Date().getFullYear()} {PRODUCT_NAME}. Built for iPhone with SwiftUI and on-device Apple Intelligence.</p>
        </footer>
      </main>
    </div>
  );
}
