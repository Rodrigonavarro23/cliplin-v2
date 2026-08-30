---
name: cycle-run
description: >-
  Implements an approved ADC (a .feature file with a complete @constraints block)
  as a small, atomic session. Closes with cycle-validate as the final step, run
  inline in this same conversation — not as a git pre-commit hook.
when_to_use: >-
  Use when the .feature file already has an approved @constraints block
  (governed_by populated, conflicts/gaps/escalation_triggers resolved) and the
  human has confirmed which scenarios to implement. Do NOT use when the ADC is
  incomplete — run cycle-init first.
---

# Skill: cycle-run

Implements `docs/tdrs/cycle-commands.md` (`cycle-run` section), adapted from the reference `acd-session-workflow.md` (external, unmodified).

## Session start rules

Before writing any code:

0. **Check extension hooks (`before_cycle_run`)** per `docs/tdrs/extension-hooks.md` — same dispatch rules as `cycle-init`: mandatory hooks must actually run, optional ones are presented to the human. Skip silently if none declared.
1. **Verify the complete ADC**: `.feature` file exists, `@constraints` has `governed_by` populated, human approved the scenarios.
2. **Load relevant context**: invoke `deterministic-context-discovery` for anything the implementation touches that wasn't already covered by the ADC's `governed_by`.
3. **Select scope**: if the human named specific scenarios, use those. If they asked for "the feature" and more than 3 scenarios are in scope, select by `@priority` per `docs/tdrs/scenario-priority.md` — all `P1` first, then `P2`, then `P3`; if more than 3 share a tier, ask the human to pick rather than guessing an order within it.
4. **Declare scope**: tell the human explicitly which scenarios (max 3) will be implemented in this session, and why those were selected (named by the human, or priority order).

## Session size rules

- Maximum 3 scenarios per session. Split into sequential sessions if the feature has more.
- If a scenario needs changes to more than 5 production files, stop and alert the human, proposing a split — do not silently proceed. (If proceeding anyway because the artifacts are inseparable — e.g. one coherent skill file — say so explicitly, as this session's own kickoff message did.)

## Session modes

- **Authorship session**: all in-scope scenarios are `@status:new`.
- **Evolution session**: at least one in-scope scenario is `@status:modified`.

Announce the detected mode before writing anything.

## Execution rules

- Implement the described behavior first; for scenarios with an automated-test surface, write the failing test before the implementation (TDD). For scenarios that describe agent/skill procedures (like this project's own scenarios), "implementation" is the skill/agent/template file itself — there is no separate test layer to fake out.
- Do not mix implementation of unrelated features in the same session.
- If a TDR/ADR needs to change to make this scenario correct, pause and inform the human before continuing.
- If an undocumented gap surfaces mid-session, add it to the `.feature` file's `@constraints.gaps` and ask the human before proceeding past it.

### Escalation triggers

Before writing anything, read the `escalation_triggers` list in `@constraints`. If any listed condition (or an unforeseen one that's equally unsafe to decide alone) is encountered: stop immediately, describe the situation and options to the human, and resume only after an explicit decision. Add unforeseen triggers to the list once resolved.

## Session close rules — `cycle-validate`

This is the last step of every `cycle-run` session, run inline (not a git hook — deferred per `docs/adrs/000-cliplin-v2-agent-native.md`). Per `docs/tdrs/cycle-validate-report.md`, every run of `cycle-validate` — pass or fail — MUST produce a persisted report at `.cliplin/cycles/<cycle_id>.json` before anything is reported to the human. Do not narrate "checks passed" without having written this file first; the file is the source of truth, the chat message summarizes it.

1. **Artifact consistency** (`AC-1`–`AC-4`): the `.feature` file has a `@constraints` block; every path in `governed_by` exists on disk. Run the actual `Read`/`Glob` for each path — the literal result (found/not found, or file content confirming the block) becomes that check's `evidence`. A check written without having actually run the corresponding `Read`/`Glob` is invalid — do not fabricate evidence.
2. **Traceability** (`TR-1`–`TR-2`): every scenario implemented in this session is traceable to code/content produced in this session; no orphan production files with no corresponding scenario. Evidence: the specific file path(s) each scenario maps to.
3. **Write the report**: assemble all check results into `.cliplin/cycles/<cycle_id>.json` per the schema in `docs/tdrs/cycle-validate-report.md`. Set `overall` to `"fail"` if any check failed, `"pass"` otherwise. Write this file regardless of outcome.
4. **If `overall` is `"fail"`**: do NOT close the cycle. Report the specific failure to the human (referencing the report file) and wait — no automatic retry, no silent skip, no partial close. Do not run `context-summary-sync` yet.
5. **If `overall` is `"pass"`**:
   - Set `closed_at` in the report to the current timestamp.
   - Update scenario tags: `@status:new`/`@status:modified` → `@status:implemented`, add `@changed:YYYY-MM-DD`.
   - Invoke `context-summary-sync` (`skills/context-summary-sync/SKILL.md`) to update `.cliplin/context-summary.yaml` — only now, with a passing report on disk as the checkable precondition.
   - Check extension hooks (`after_cycle_run`) per `docs/tdrs/extension-hooks.md` — same dispatch rules, mandatory ones must actually run.
   - Report to the human what was implemented, referencing the report file path, not just asserting completion.

## Explicit scope note

This project has no pre-commit hook yet (see `docs/adrs/000-cliplin-v2-agent-native.md`, Consequences → Negative). `cycle-validate` here depends on the agent actually running this step — a known, accepted determinism gap for this phase, not a silent oversight.
