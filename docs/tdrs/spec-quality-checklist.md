---
tdr: "1.0"
id: "spec-quality-checklist"
title: "Spec Quality Checklist — Separate from @constraints"
summary: "cycle-init validates a drafted .feature against a quality checklist (testability, no leaked implementation detail, measurable outcomes) before critique, self-correcting up to 3 iterations. @constraints proves governance/traceability; this proves the spec itself is well-formed. Adapted from GitHub Spec Kit's requirements.md checklist."
---

# rules

## Resolution note (why this file exists)

`@constraints` (`docs/tdrs/feature-constraints-format.md`) proves a feature is traceable to governing docs — it says nothing about whether the scenarios themselves are well-written. The comparative report against GitHub Spec Kit (2026-07-13) found their `requirements.md` checklist genuinely useful for this and missing here.

## When this runs (MUST follow)

Immediately after drafting scenarios (`cycle-init` Step 2, point 5 "Draft scenarios") and before critique (point 6). Applies to authorship mode; evolution mode runs it only against the delta, same scoping principle as the delta-only critique in Evo-Step 2.

## Checklist (MUST evaluate every item)

Write the result to `docs/features/<slug>.checklist.md`:

```markdown
# Spec Quality Checklist: <Feature Name>

## Content quality
- [ ] No implementation detail leaked into Feature:/Scenario: text (no framework, language, API names)
- [ ] Written in business/observable-behavior language, not system-internal language

## Scenario completeness
- [ ] Every scenario has concrete Given/When/Then — no placeholder or vague steps
- [ ] Every scenario is independently testable on its own
- [ ] Edge cases implied by governing TDRs/ADRs are covered or explicitly noted as a gap
- [ ] Every agent-proposed scenario has `@type` and, if edge/complementary, a `# why:` citing its source

## Constraints completeness
- [ ] `governed_by` is non-empty
- [ ] `conflicts` and `gaps` are explicit lists (`[]` if none), never omitted
```

## Self-correction rule (MUST follow)

1. Evaluate every item.
2. If any item fails: fix the draft directly (this is not a `[GAP]`/`[CONFLICT]` needing human decision — it's a spec quality issue, the agent's own responsibility to fix before showing the human a critique).
3. Re-run the checklist.
4. **Maximum 3 iterations.** If items still fail after 3 iterations, stop, document the remaining failures in the checklist file's Notes, and surface them to the human alongside the critique report (Step 2/Step 3) rather than looping forever.

## Explicit non-goal

This checklist does not replace the critique step (`[CONTEXT-GAP]`/`[GAP]`/`[CONFLICT]`/`[AMBIGUITY]`, per `docs/adrs/000-cliplin-v2-agent-native.md` reference to the authorship cycle) — critique evaluates the spec against governing context; this checklist evaluates the spec's internal quality regardless of context. Both run, in this order: checklist first (self-correctable), critique second (needs human decisions).

code_refs:
  - "docs/tdrs/feature-constraints-format.md"
  - "skills/cycle-init/SKILL.md"
