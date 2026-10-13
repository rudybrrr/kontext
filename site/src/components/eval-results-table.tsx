import type { ReactNode } from "react";
import type { EvalResultsFile, EvalSuiteReport } from "@/lib/eval-types";
import { formatMetric, formatMs } from "@/lib/eval-results";

function TableShell({ children }: { children: ReactNode }) {
  return (
    <div className="overflow-x-auto rounded-2xl border border-zinc-200 dark:border-zinc-800">
      <table className="min-w-full divide-y divide-zinc-200 text-left text-sm dark:divide-zinc-800">
        {children}
      </table>
    </div>
  );
}

export function EvalResultsTable({ data }: { data: EvalResultsFile }) {
  if (data.status !== "complete" || !data.report) {
    return (
      <TableShell>
        <thead className="bg-zinc-50 dark:bg-zinc-900/60">
          <tr>
            <th className="px-4 py-3 font-medium">Pipeline</th>
            <th className="px-4 py-3 font-medium">Precision</th>
            <th className="px-4 py-3 font-medium">Recall</th>
            <th className="px-4 py-3 font-medium">Exact date</th>
            <th className="px-4 py-3 font-medium">R@5 (blend)</th>
            <th className="px-4 py-3 font-medium">p95 extract</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-zinc-200 bg-white dark:divide-zinc-800 dark:bg-zinc-950">
          {["deterministic", "model", "merged"].map((pipeline) => (
            <tr key={pipeline}>
              <td className="px-4 py-3 capitalize text-zinc-700 dark:text-zinc-200">{pipeline}</td>
              <td className="px-4 py-3 text-zinc-500" colSpan={5}>pending — run CaptureEvals on device</td>
            </tr>
          ))}
        </tbody>
      </TableShell>
    );
  }

  return <EvalResultsTableFilled report={data.report} />;
}

function EvalResultsTableFilled({ report }: { report: EvalSuiteReport }) {
  const blend = report.searchPipelines.find((row) => row.mode === "blend");

  return (
    <TableShell>
      <thead className="bg-zinc-50 dark:bg-zinc-900/60">
        <tr>
          <th className="px-4 py-3 font-medium">Pipeline</th>
          <th className="px-4 py-3 font-medium">Precision</th>
          <th className="px-4 py-3 font-medium">Recall</th>
          <th className="px-4 py-3 font-medium">Exact date</th>
          <th className="px-4 py-3 font-medium">R@5 (blend)</th>
          <th className="px-4 py-3 font-medium">p95 extract</th>
        </tr>
      </thead>
      <tbody className="divide-y divide-zinc-200 bg-white dark:divide-zinc-800 dark:bg-zinc-950">
        {report.actionPipelines.map((row) => (
          <tr key={row.pipeline}>
            <td className="px-4 py-3 capitalize text-zinc-800 dark:text-zinc-100">{row.pipeline}</td>
            <td className="px-4 py-3 font-mono text-zinc-700 dark:text-zinc-300">{formatMetric(row.overall.precision)}</td>
            <td className="px-4 py-3 font-mono text-zinc-700 dark:text-zinc-300">{formatMetric(row.overall.recall)}</td>
            <td className="px-4 py-3 font-mono text-zinc-700 dark:text-zinc-300">{formatMetric(row.exactDateAccuracy)}</td>
            <td className="px-4 py-3 font-mono text-zinc-700 dark:text-zinc-300">
              {blend ? formatMetric(blend.recallAt5) : "pending"}
            </td>
            <td className="px-4 py-3 font-mono text-zinc-700 dark:text-zinc-300">{formatMs(row.latencyMs.p95Ms)}</td>
          </tr>
        ))}
      </tbody>
    </TableShell>
  );
}
