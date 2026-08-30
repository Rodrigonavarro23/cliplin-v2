---
name: reverse-engineer
description: >-
  Surveys a repo with no Cliplin specs (code, docs, project signals) and proposes
  baseline ADRs/TDRs/features for human approval. As a final step, generates or
  updates .cliplin/context-summary.yaml from whatever was approved, via
  context-summary-sync. Partial coverage is acceptable.
when_to_use: >-
  Use when a repo (often a coordinator's child submodule flagged by scout) has no
  Cliplin specs and no context-summary.yaml. Never invoke automatically — always on
  explicit human confirmation, typically in response to a scout escalation_trigger
  recommending it. Do NOT use for specifying new/changed behavior that doesn't exist
  yet in the code — that's cycle-init's job, not this skill's.
---

# Skill: reverse-engineer

Implements `docs/tdrs/reverse-engineering.md`.

## When this runs

Only on explicit human request. The most common trigger: a coordinator relayed a `scout` `escalation_trigger` ("no context-summary.yaml found ... recommend running reverse-engineer") and the human confirmed. Never spawned automatically by `cycle-init`, `scout`, or a coordinator.

## Procedure

1. **Survey**: read the repo's existing code structure, README, docs (if any, even non-Cliplin ones), and any other project signals (package manifests, test directory layout, CI config) to infer what the software actually does today.
2. **Propose baseline specs**: draft candidate `.feature` files (behavior visibly present in the code), TDRs (technical conventions actually followed — naming, patterns, forbidden approaches evident from the code), and ADRs (architectural choices inferable from structure — e.g. why a given framework/pattern is used, if evident). Mark every proposal `[AGENT PROPOSAL — awaiting human approval]`, same convention as `cycle-init`.
3. **Human reviews**: the human approves, rejects, or modifies each proposed artifact — same authority rules as any ADC artifact (`docs/tdrs/feature-constraints-format.md` — the agent proposes, the human owns).
4. **Write approved artifacts**: only what was explicitly approved gets written to `docs/adrs/`, `docs/tdrs/`, `docs/features/` in this repo.
5. **Accept partial coverage**: if the repo is large or ambiguous, propose what can be confidently inferred in this pass and stop there — do not force full coverage. Note unsurveyed areas as an open gap in your final report to the human, not as a blocking failure.
6. **Bootstrap `context-summary.yaml`**: invoke `context-summary-sync` (`skills/context-summary-sync/SKILL.md`) using only the artifacts approved in step 4 as input. If `.cliplin/context-summary.yaml` doesn't exist yet, this creates it from `templates/context-summary.template.yaml`; if it exists (a prior partial run), this adds to it — same additive behavior as any other `context-summary-sync` invocation.

## Constraints (MUST follow)

- Do not treat this as a `cycle-init` authorship session — no session-size limit applies (this is a survey of existing behavior, not new spec authorship), but every proposed artifact still needs explicit human approval before being written.
- Do not infer behavior that isn't actually evidenced in the code — if uncertain, note it as a gap rather than guessing a `.feature` scenario into existence.
- Running this skill on a repo does not by itself make that repo's ADC "complete" for any pending feature request — it only establishes a baseline. A subsequent `cycle-init`/`cycle-worker` invocation for the actual feature request still runs its own full procedure.
