const testFlightUrl = process.env.NEXT_PUBLIC_TESTFLIGHT_URL;

export function TestFlightCTA({ className = "" }: { className?: string }) {
  if (testFlightUrl) {
    return (
      <a
        href={testFlightUrl}
        className={`inline-flex items-center justify-center rounded-full bg-sky-600 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-sky-600/25 transition hover:bg-sky-500 ${className}`}
        rel="noopener noreferrer"
        target="_blank"
      >
        Join TestFlight
      </a>
    );
  }

  return (
    <span
      className={`inline-flex cursor-not-allowed items-center justify-center rounded-full border border-dashed border-zinc-400 px-6 py-3 text-sm font-semibold text-zinc-500 dark:border-zinc-600 dark:text-zinc-400 ${className}`}
      title="TestFlight link not configured yet"
    >
      TestFlight — coming soon
    </span>
  );
}
