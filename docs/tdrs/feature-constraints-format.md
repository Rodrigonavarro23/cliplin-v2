---
tdr: "1.0"
id: "feature-constraints-format"
title: "Feature Constraints Block Format (Cliplin v2)"
summary: "Definitive @constraints schema for this project: governed_by, conflicts, gaps, escalation_triggers."
---

# rules

## Resolution note (why this file exists)

Two candidate schemas were evaluated for the `@constraints` block: one using a separate `assumptions` field, one using `escalation_triggers`. This project adopts `escalation_triggers` as definitive, since ACD is this project's native default flow (see `docs/adrs/000-cliplin-v2-agent-native.md`) and `escalation_triggers` maps directly to its mid-implementation stop-and-ask discipline. `assumptions` is dropped as a separate field — a resolved assumption is recorded either as an entry removed from `gaps` (if it fully resolves the gap) or as a governing doc added to `governed_by` (if it required a new TDR/ADR).

## Format (MUST follow)

- Gherkin tag `@constraints`, placed immediately before `Feature:` (feature-level) or `Scenario:` (scenario-level).
- Each field is a YAML comment block, every line prefixed with `# `.
- 100% valid Gherkin — BDD runners ignore it; the agent reads it as structured text.

## Fields

- **`governed_by`** (list of paths): TDRs/ADRs/business docs that actively govern this feature or scenario.
- **`conflicts`** (list of strings): contradictions detected between governing documents. `[]` if none.
- **`gaps`** (list of strings): assumed behavior not covered by any governing document. `[]` if none.
- **`escalation_triggers`** (list of strings): concrete conditions that, if encountered during `cycle-run`, require stopping and asking the human — not covered by any governing doc, unsafe to decide autonomously. `[]` if none. Each entry is a specific situation, not a category.

## Example

```gherkin
@constraints
# governed_by:
#   - docs/tdrs/multi-repo-coordination.md
#   - docs/adrs/000-cliplin-v2-agent-native.md
# conflicts: []
# gaps:
#   - "No spec yet for what happens if two scout sub-agents return conflicting relevance verdicts for the same repo"
# escalation_triggers:
#   - "A child repo's context-summary.yaml is missing or malformed at scout time"
Feature: ...
```

## Completeness rule before implementation

`cycle-run` MUST NOT start if `governed_by` is empty, or if any `conflicts`/`gaps`/`escalation_triggers` item lacks an explicit human decision recorded in the cycle's conversation history.

code_refs:
  - "docs/features/"
  - "docs/adrs/000-cliplin-v2-agent-native.md"
