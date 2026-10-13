# Capture evaluation suite

The `CaptureEvals` target runs labelled fixtures under `Evals/` against on-device extraction and search. It is separate from `CaptureTests` and is intended for physical devices with Apple Intelligence when measuring Foundation Models pipelines.

## Fixtures

| File | Contents |
|------|----------|
| `Evals/captures.json` | 100 synthetic captures (~40 text, ~30 screenshot-style, ~30 URL) with expected actions and `Asia/Singapore` reference dates |
| `Evals/search_queries.json` | 40 labelled queries with relevant capture ids |
| `Evals/scripts/generate_captures.py` | Regenerates fixture JSON |
| `Evals/scripts/render_screenshots` | Optional PNG fixtures (requires Pillow) |

## Run on a physical device

1. Open the project (`xcodegen generate` if you use XcodeGen).
2. Select the **CaptureEvals** scheme.
3. Choose a physical iPhone with iOS 26 and Apple Intelligence enabled (for model + merged pipelines).
4. Product → Test (⌘U), or:

```bash
xcodegen generate
xcodebuild -scheme CaptureEvals \
  -destination 'platform=iOS,name=Your iPhone' \
  test
```

5. In the test report, open the attachment **`capture-evals-results.json`** and the Xcode console markdown table.

Deterministic extraction always runs. **Model-only** and **merged** pipelines run only when Foundation Models is available; otherwise they are skipped.

## Metrics

**Action extraction** (per pipeline: deterministic, model, merged):

- Precision / recall (overall and per `event` / `reminder` / `followUp`)
- Match rule: same kind, title token overlap ≥ 0.5, anchor date within ±15 minutes (all-day: same calendar day)
- Exact-date accuracy and ±15 minute accuracy on matched pairs
- All-day flag error rate on matched all-day expectations
- False-positive rate on negative captures (no expected actions)

**Search** (lexical-only, semantic-only, 0.45 blend):

- Recall@1 / @5 / @10 (fraction of labelled relevant captures appearing in top *k*)
- p50 / p95 latency per query (ContinuousClock)

## Targets (goals)

| Metric | Target |
|--------|--------|
| Action precision | ≥ 0.85 |
| Action recall | ≥ 0.70 |
| Exact date accuracy | ≥ 0.85 |
| Search R@5 (blend) | ≥ 0.85 |
| Extraction p95 latency | < 3000 ms |

## Latest results

| Run date | Device | Deterministic P/R | Merged P/R | Exact date | Search R@5 (blend) | Extraction p95 ms |
|----------|--------|-------------------|------------|------------|--------------------|-------------------|
| | | | | | | |

Fill in after running on hardware.
