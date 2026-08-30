---
tdr: "1.0"
id: "scenario-priority"
title: "Scenario Priority — P1/P2/P3, Independent of @type"
summary: "Scenarios carry an optional @priority:P1/P2/P3 tag, orthogonal to @type:main/edge/complementary. cycle-run's existing max-3-scenarios-per-session rule uses priority to self-select which scenarios go first when the human hasn't specified. Adapted from GitHub Spec Kit's prioritized independently-testable user stories."
---

# rules

## Resolution note (why this file exists)

`@type:main/edge/complementary` (used inline in this project's feature files, e.g. `docs/features/cycle-init.feature`) classifies *why* a scenario exists, not *how important it is to ship first*. `docs/tdrs/cycle-commands.md` already caps `cycle-run` sessions at 3 scenarios (inherited from the external `acd-session-workflow.md` reference), but nothing decides *which* 3 when a feature has more. The comparative report against GitHub Spec Kit (2026-07-13) found their P1/P2/P3 user-story prioritization — each independently testable, each a valid standalone MVP slice — solves exactly this, and it's missing here.

## Rule (MUST follow)

- Scenarios MAY carry `@priority:P1`, `@priority:P2`, or `@priority:P3` (P1 highest). Untagged scenarios are treated as P2 by default — not required to tag every scenario, but priority-aware selection needs a default.
- A scenario tagged with any priority MUST be independently testable/deliverable on its own — if implementing only that scenario would leave the feature broken or meaningless without others, it should not be tagged `P1` (it isn't a standalone slice); reconsider the scenario boundary instead of the tag.
- **Tag order**: `@type:*` → `# why: ...` (if edge/complementary) → `@priority:P*` (if tagged) → `@status:*` → `@changed:*`.

## Interaction with `cycle-run` session-size rule (MUST follow)

`docs/tdrs/cycle-commands.md` caps a `cycle-run` session at 3 scenarios. When the human requests implementation of "the feature" without naming specific scenarios, and more than 3 are in scope:

1. Select scenarios in priority order: all `P1` first, then `P2`, then `P3`.
2. If more than 3 scenarios share the same priority, ask the human which to select first — do not guess an arbitrary sub-order within a priority tier.
3. Announce the selected scope explicitly before starting (this is additive to, not a replacement for, the existing "declare scope" session-start rule).

## Explicit non-goal

Priority does not affect `@type` classification or the `# why:` requirement for edge/complementary scenarios — a `P1` scenario can still be `@type:edge` if that's genuinely why it was proposed; the two tags answer different questions.

code_refs:
  - "docs/tdrs/cycle-commands.md"
  - "skills/cycle-run/SKILL.md"
