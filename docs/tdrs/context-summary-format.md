---
tdr: "1.0"
id: "context-summary-format"
title: "context-summary.yaml — Per-Repo Concept Map"
summary: "Schema and lifecycle for context-summary.yaml: a map of concepts, rules, and definitions (not a file index), generated and updated as part of ACD cycle closure."
---

# rules

## Purpose (MUST understand)

`context-summary.yaml` is NOT a file/path index. It is a concept map: business/technical terms, rules, and definitions known to exist in this repo's specs, plus hints on where to find the governing document for each. It exists so that:

- A `scout` sub-agent (see `docs/tdrs/multi-repo-coordination.md`) can judge relevance to a cross-repo request by reading ONE small file, without reading the full `docs/` tree.
- A `cycle-init` run in this repo can check "was this already decided" before running a full `deterministic-context-discovery` pass.

## Location

`.cliplin/context-summary.yaml`, one per repo, at repo root.

## Schema

```yaml
concepts:
  - term: <string>            # domain term or concept name
    definition: <string>      # one-line definition
    find_via:                 # paths to governing docs, most relevant first
      - <path>
rules:
  - id: <string>               # short rule id, e.g. R-014
    summary: <string>          # one-line rule statement
    source: <path>             # governing doc that states this rule
last_cycle: <string>           # identifier of the ACD cycle that last updated this file
```

## Lifecycle (MUST follow)

- Generated on first `cycle-init` **or** first `reverse-engineer` run (see `docs/tdrs/reverse-engineering.md`) in a repo that has none — two possible entry points to the same artifact, both via `context-summary-sync`.
- Updated as the final step of `cycle-run` close (see `docs/tdrs/cycle-commands.md`), immediately after `cycle-validate` passes: the agent adds any concept/rule it introduced or relied upon during the session that is not yet captured.
- Also updated at the close of a `reverse-engineer` run, from whatever baseline specs were approved during that survey — partial coverage is acceptable, `context-summary-sync` is additive.
- Never manually maintained as the primary source — it is a derived artifact regenerated from the actual governing docs (`docs/adrs/`, `docs/tdrs/`, `docs/business/`, and enabled bundles under `.cliplin/knowledge/**` per `docs/tdrs/knowledge-bundle-management.md`) plus the session's own work; treat drift (a `find_via` path that no longer exists) as a signal to regenerate, not to hand-edit.

## Consumer contract

- `scout` sub-agents (per `docs/tdrs/multi-repo-coordination.md`) MUST read only this file when judging relevance — never the full `docs/` tree — to keep the scout phase cheap.
- A worker (leaf) agent reads this file FIRST, before running a full `deterministic-context-discovery` pass, to shortcut to `find_via` paths when the query already matches a known concept.

code_refs:
  - "docs/adrs/000-cliplin-v2-agent-native.md"
  - "docs/tdrs/multi-repo-coordination.md"
