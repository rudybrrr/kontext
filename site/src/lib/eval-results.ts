import { readFile } from "fs/promises";
import path from "path";
import type { EvalResultsFile } from "./eval-types";

export async function loadEvalResults(): Promise<EvalResultsFile> {
  const filePath = path.join(process.cwd(), "data", "eval-results.json");
  const raw = await readFile(filePath, "utf8");
  return JSON.parse(raw) as EvalResultsFile;
}

export function formatMetric(value: number | null | undefined, digits = 3): string {
  if (value === null || value === undefined || Number.isNaN(value)) return "pending";
  return value.toFixed(digits);
}

export function formatMs(value: number | null | undefined): string {
  if (value === null || value === undefined || Number.isNaN(value)) return "pending";
  return `${Math.round(value)} ms`;
}
