---
tdr: "1.0"
id: "reverse-engineering"
title: "Reverse Engineering — Bootstrap Specs and context-summary.yaml from Existing Code"
summary: "Scope for this project's reverse-engineer skill: survey a repo with no Cliplin specs, propose baseline ADRs/TDRs/features, and generate the first context-summary.yaml."
---

# rules

## Resolution note (why this file exists)

Testing `cycle-init`'s coordinator path against real, unspec'd repos (see `docs/features/cycle-init.feature` scenario "scout recommends reverse-engineer...") surfaced a missing capability: every real-world repo a coordinator is likely to add as a submodule has no Cliplin specs and no `context-summary.yaml`. The original design (escalate generically) is correct to stop and ask, but was not actionable. This project needs its own `reverse-engineer` skill — adapted from the external `cliplin-reverse-engineer` reference (unmodified) — extended to also produce the first `context-summary.yaml`, closing the loop with `docs/tdrs/context-summary-format.md`.

## Scope (MUST follow)

`reverse-engineer` surveys an existing repo's code, documentation, and project signals to propose baseline Cliplin specs (feature files, ADRs, TDRs, business docs) — same survey scope as the external reference skill. This project adds one responsibility not present in the reference: as its final step, it generates or updates `.cliplin/context-summary.yaml` (per `docs/tdrs/context-summary-format.md`) from whatever baseline specs were approved during the run — reusing the `context-summary-sync` skill rather than duplicating its logic.

Partial coverage is acceptable: if the repo is too large or ambiguous to fully survey in one run, `reverse-engineer` proposes what it can confidently infer, marks the rest as an open gap, and still generates a `context-summary.yaml` reflecting only what was actually approved. `context-summary-sync` is additive by design (see `docs/tdrs/context-summary-format.md`, Lifecycle) — a partial bootstrap is not a broken one, later runs add to it.

## Trigger (MUST NOT be automatic)

`reverse-engineer` is never invoked automatically by a coordinator or scout. When `scout` (per `docs/tdrs/multi-repo-coordination.md`) reports a child repo has no `context-summary.yaml`, the coordinator surfaces this to the human as a concrete recommendation ("this repo has no specs — run `reverse-engineer` here first?") and waits for an explicit decision. The human may decline and let `cycle-worker` proceed without a baseline — that is a valid choice, not an error.

## Relationship to `cycle-init` (MUST understand)

`reverse-engineer` and `cycle-init` solve different problems and are not interchangeable:

- `reverse-engineer`: surveys **existing, unspecified** behavior already in the codebase. Produces baseline specs for what already exists.
- `cycle-init`: specifies **new or changed** behavior that doesn't exist yet, or evolves an already-specced feature.

Running `reverse-engineer` on a repo does not itself constitute a `cycle-init` authorship session, and does not require session-size limits (`docs/tdrs/cycle-commands.md`'s `cycle-run` max-3-scenarios rule) — it is a survey, not an implementation session. Specs it proposes still require human approval before being considered part of any repo's ADC, same as any agent-proposed artifact.

code_refs:
  - "docs/adrs/000-cliplin-v2-agent-native.md"
  - "docs/tdrs/context-summary-format.md"
  - "docs/tdrs/multi-repo-coordination.md"
