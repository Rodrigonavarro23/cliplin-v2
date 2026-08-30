---
tdr: "1.0"
id: "cycle-validate-report"
title: "cycle-validate Report — Persisted, Durable Validation Evidence"
summary: "cycle-validate MUST write a structured report file with per-check evidence, not just narrate pass/fail in conversation. Makes validation auditable by anything that can read a file, independent of the session transcript — the mechanical step short of a pre-commit hook."
---

# rules

## Resolution note (why this file exists)

Testing this project against GitHub Spec Kit (comparative report, 2026-07-13) confirmed Cliplin v2's central determinism claim has one real hole: `cycle-validate` (per `docs/tdrs/cycle-commands.md`) runs checks and reports pass/fail in prose, but nothing forces the checks to have actually been executed — the agent could assert "checks passed" without having run them. This TDR closes that gap without yet building the deferred pre-commit hook (`docs/adrs/000-cliplin-v2-agent-native.md`, Consequences → Negative): instead of trusting the conversation, `cycle-validate` now produces a durable artifact any future reader — human, hook, or another agent — can verify independently.

## Location and format (MUST follow)

`.cliplin/cycles/<cycle_id>.json`, one file per `cycle-run` session that reaches `cycle-validate`. `cycle_id` uses the same convention as `context-summary.yaml`'s `last_cycle` field (see `docs/tdrs/context-summary-format.md`): `<feature-slug>-<YYYY-MM-DD>`, or `<feature-slug>-evolution-<short-description>-<YYYY-MM-DD>` for evolution sessions.

```json
{
  "cycle_id": "<string>",
  "feature_file": "<path to the .feature file this session implements>",
  "scenarios_in_scope": ["<scenario name>", "..."],
  "checks": [
    {
      "id": "AC-1",
      "description": "@constraints block present in feature_file",
      "result": "pass | fail",
      "evidence": "<what was actually read/grepped to reach this result — a literal quote or command output, not a restatement of the rule>"
    }
  ],
  "overall": "pass | fail",
  "closed_at": "<ISO 8601 timestamp, or null if overall is fail>"
}
```

Check `id`s reuse the codes already referenced by `docs/tdrs/cycle-commands.md` (`AC-1`–`AC-4` artifact consistency, `TR-1`–`TR-2` traceability), sourced from the external `acd-pipeline-gates.md` reference.

## Rules (MUST follow)

- `cycle-validate` MUST write this file on every run, whether the result is `pass` or `fail` — a failed validation still produces a report, it just has `overall: "fail"` and `closed_at: null`.
- Every `evidence` field MUST be the actual output of the check (e.g. the real result of a `Read`/`Glob` call), never a restatement like `"path exists"` with no proof behind it. A check with no evidence is not a valid check.
- The file is written BEFORE the agent reports completion to the human — the report is not a summary of what was said, the report is the source the summary is built from.
- `context-summary-sync` (see `docs/tdrs/context-summary-format.md`) only runs after a report with `overall: "pass"` exists for this cycle — this makes the existing rule ("does not update context-summary.yaml until the gap is resolved", `docs/tdrs/cycle-commands.md`) checkable against a file instead of trusting that the agent actually waited.
- This file is append-only history, not a derived/regenerable artifact like `context-summary.yaml` — never overwrite a prior cycle's report; each `cycle_id` gets its own file.

## Explicit scope note

This is still not a git hook — nothing blocks a commit from happening if this file says `overall: "fail"`. It closes the "did validation actually run" gap, not the "can a bad commit still land" gap. The latter remains the deferred pre-commit hook (`docs/adrs/000-cliplin-v2-agent-native.md`).

code_refs:
  - "docs/tdrs/cycle-commands.md"
  - "docs/tdrs/context-summary-format.md"
  - "docs/adrs/000-cliplin-v2-agent-native.md"
