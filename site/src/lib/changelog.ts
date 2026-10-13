import { readFile } from "fs/promises";
import path from "path";

export type ChangelogEntry = {
  title: string;
  body: string;
};

export async function loadChangelog(): Promise<ChangelogEntry[]> {
  const candidates = [
    path.join(process.cwd(), "..", "CHANGELOG.md"),
    path.join(process.cwd(), "content", "CHANGELOG.md"),
  ];
  let markdown = "";
  for (const candidate of candidates) {
    try {
      markdown = await readFile(candidate, "utf8");
      break;
    } catch {
      continue;
    }
  }
  if (!markdown) return [];

  const entries: ChangelogEntry[] = [];
  const sections = markdown.split(/\n(?=## )/);
  for (const section of sections) {
    const trimmed = section.trim();
    if (!trimmed.startsWith("## ")) continue;
    const lines = trimmed.split("\n");
    const title = lines[0].replace(/^##\s+/, "").trim();
    const body = lines.slice(1).join("\n").trim();
    if (title.toLowerCase() === "changelog") continue;
    entries.push({ title, body });
  }
  return entries;
}
