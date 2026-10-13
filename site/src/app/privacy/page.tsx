import Link from "next/link";
import type { Metadata } from "next";
import { PRODUCT_NAME } from "@/lib/constants";

export const metadata: Metadata = {
  title: `Privacy Policy — ${PRODUCT_NAME}`,
  description: `How ${PRODUCT_NAME} handles your data on iPhone.`,
};

export default function PrivacyPage() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-16">
      <Link href="/" className="text-sm text-sky-600 hover:underline dark:text-sky-400">← Back to home</Link>
      <h1 className="mt-8 text-3xl font-semibold text-zinc-900 dark:text-zinc-50">Privacy Policy</h1>
      <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">Last updated: October 2025</p>

      <div className="prose prose-zinc mt-10 max-w-none dark:prose-invert prose-p:text-zinc-600 dark:prose-p:text-zinc-300">
        <p>
          {PRODUCT_NAME} (&quot;the app&quot;) is an iPhone utility that helps you save text, links, and images, organize them on-device,
          and optionally approve suggested calendar events or reminders. This policy describes what the app does with your information.
        </p>

        <h2>Summary</h2>
        <ul>
          <li>Your captures stay on your iPhone unless you explicitly approve writing to Apple Calendar or Reminders.</li>
          <li>We do not operate a cloud account, sync service, or analytics pipeline in the app.</li>
          <li>We do not sell your data.</li>
        </ul>

        <h2>Data stored on your device</h2>
        <p>
          The app stores captures, extracted text, embeddings, context assignments, and proposed actions in local SwiftData storage
          (including a shared App Group container used with the Share Extension). Images are stored as files in that container.
          This data remains on your device and is not transmitted to us or to third-party servers by the app.
        </p>

        <h2>On-device processing</h2>
        <p>
          Enrichment, semantic search, and action extraction use Apple frameworks (including Foundation Models when available,
          NaturalLanguage, and Vision OCR) on your device. When Apple Intelligence is unavailable, deterministic fallbacks run locally.
          The app does not send capture content to external AI services.
        </p>

        <h2>Network use</h2>
        <p>
          Saving a capture does not require network access. For URL captures, the app may fetch page HTML or link metadata to improve
          titles and extraction; that request goes directly from your device to the URL you saved. You control what URLs you capture.
        </p>

        <h2>Calendar and Reminders</h2>
        <p>
          The app only requests Calendar or Reminders access when you tap to approve a proposed action. Calendar access is write-only
          for creating events you confirm. Reminders access is used to create reminders you confirm. The app does not read your existing
          calendars to display or mine your schedule. Approved items are stored in Apple&apos;s Calendar and Reminders apps under your Apple ID.
        </p>

        <h2>What we do not collect</h2>
        <p>
          The app does not include third-party analytics, advertising identifiers, or crash reporting SDKs that exfiltrate capture content.
          We do not collect contact lists, photos beyond what you explicitly share into the app, or location in the background.
        </p>

        <h2>Marketing site</h2>
        <p>
          This website is static and does not use cookies or trackers for capture content. If you join a TestFlight link hosted by Apple,
          Apple&apos;s terms apply to that program.
        </p>

        <h2>Children</h2>
        <p>The app is not directed at children under 13.</p>

        <h2>Changes</h2>
        <p>We may update this policy as the app evolves. Material changes will be reflected on this page.</p>

        <h2>Contact</h2>
        <p>
          Questions about privacy can be sent to the project maintainers via your usual open-source contact channel for this repository.
        </p>
      </div>
    </main>
  );
}
