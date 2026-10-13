export type EvalPRMetrics = {
  precision: number;
  recall: number;
  truePositives: number;
  falsePositives: number;
  falseNegatives: number;
};

export type EvalLatencyStats = {
  p50Ms: number;
  p95Ms: number;
  sampleCount: number;
};

export type EvalActionPipelineResult = {
  pipeline: string;
  overall: EvalPRMetrics;
  perKind: Record<string, EvalPRMetrics>;
  exactDateAccuracy: number;
  fifteenMinuteDateAccuracy: number;
  allDayErrorRate: number;
  negativeFalsePositiveRate: number;
  latencyMs: EvalLatencyStats;
};

export type EvalSearchPipelineResult = {
  mode: string;
  recallAt1: number;
  recallAt5: number;
  recallAt10: number;
  latencyMs: EvalLatencyStats;
};

export type EvalSuiteReport = {
  generatedAtISO: string;
  deviceModel: string;
  timezone: string;
  actionPipelines: EvalActionPipelineResult[];
  searchPipelines: EvalSearchPipelineResult[];
  targets: {
    precision: number;
    recall: number;
    exactDateAccuracy: number;
    recallAt5: number;
    extractionP95Ms: number;
  };
};

export type EvalResultsFile = {
  status: "pending" | "complete";
  report: EvalSuiteReport | null;
};
