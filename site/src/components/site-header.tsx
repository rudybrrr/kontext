import Link from "next/link";
import { PRODUCT_NAME } from "@/lib/constants";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-zinc-200/80 bg-white/80 backdrop-blur-md dark:border-zinc-800/80 dark:bg-zinc-950/80">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="text-lg font-semibold tracking-tight text-zinc-900 dark:text-zinc-50">
          {PRODUCT_NAME}
        </Link>
        <nav className="flex items-center gap-6 text-sm text-zinc-600 dark:text-zinc-300">
          <a href="#how-it-works" className="hover:text-zinc-900 dark:hover:text-white">How it works</a>
          <a href="#evals" className="hover:text-zinc-900 dark:hover:text-white">Evals</a>
          <Link href="/privacy" className="hover:text-zinc-900 dark:hover:text-white">Privacy</Link>
        </nav>
      </div>
    </header>
  );
}
