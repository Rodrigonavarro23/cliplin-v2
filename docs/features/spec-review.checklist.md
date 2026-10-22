# Spec Quality Checklist: Spec review

## Content quality
- [x] No implementation detail leaked into Feature:/Scenario: text — "python3", "lint", "report" are what the user sees; no script path, flag or file name in steps
- [x] Written in business/observable-behavior language

## Scenario completeness
- [x] Every scenario has concrete Given/When/Then
- [x] Every scenario is independently testable on its own
- [x] Edge cases implied by governing TDRs are covered (missing python3 — plugin-packaging; project conventions — spec-review TDR)
- [x] Every agent-proposed scenario has `@type` and, if edge/complementary, a `# why:`

## Constraints completeness
- [x] `governed_by` is non-empty
- [x] `conflicts` and `gaps` are explicit lists

## Notes (2026-10-22, cycle-init authorship)
- Worker role; branch `cycle/spec-review` in worktree `../cliplin-v2-spec-review`, based on `main` (author's request: not the cliplin-mods branch).
- Origin: the wedov2 spec-reviewer agent and lint (wedov2 untouched); the Cliplin version keeps framework rules only.
- Critique: [CONFLICT] plugin-packaging allowed only bash/grep/git → RESOLVED: amended to allow a standard-library python3 helper that the skill can do without. [CONTEXT-GAP] no TDR for the review → `docs/tdrs/spec-review.md` written. [GAP] `.cliplin/reviews/` and `.gitignore` → reports are local working files like `.cliplin/cycles/`; the skill never edits `.gitignore`. [AMBIGUITY] cycle-init running spec-review → out of scope (recorded gap).
- Assumption (not answered, default taken): report mode writes `.cliplin/reviews/`; `result-only` writes nothing.
- Checklist iteration 1: all items pass.
- Sessions: (1) scenarios 1, 3, 4 (P1) — SKILL.md, lint.py; (2) scenarios 2 (P1), 5, 6 (P2); (3) scenario 7 (P3).
