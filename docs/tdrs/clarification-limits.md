---
tdr: "1.0"
id: "clarification-limits"
title: "Clarification Limits — Max 3, Prioritized"
summary: "cycle-init's interview phase (Deep-dive) is capped at 3 questions, ordered by impact: scope > security/privacy > user experience > technical details. Adapted from GitHub Spec Kit's [NEEDS CLARIFICATION] cap, confirmed effective in the comparative report (2026-07-13)."
---

# rules

## Resolution note (why this file exists)

The comparative report against GitHub Spec Kit (2026-07-13) found their interview step disciplined in a way ours wasn't: a hard cap of 3 clarification markers, explicitly prioritized. Our `cycle-init` interview (Step 2, Phase 2 "deep-dive") previously allowed "up to 4 focused questions" with no enforced priority order — open-ended enough to drift into an interrogation. This TDR adopts spec-kit's discipline.

## Rule (MUST follow)

During `cycle-init`'s authorship interview (Step 0i / Step 2 Phase 2, per `docs/tdrs/cycle-commands.md` and `plugins/cliplin-v2/skills/cycle-init/SKILL.md`):

- **Maximum 3 questions** per interview pass, never more, regardless of how many gaps the agent perceives.
- Order candidate questions by impact before selecting which 3 to ask:
  1. Scope and boundaries (what's in/out)
  2. Security/privacy implications
  3. User experience / observable behavior
  4. Technical details
- If more than 3 candidate questions exist, keep only the 3 highest-priority ones and make an informed default assumption for the rest, documenting each assumption explicitly (in the eventual `@constraints.gaps` or in the drafted scenario's own text) rather than asking.
- This cap applies per interview pass, not per cycle — if the human's answers open genuinely new, higher-priority gaps, a second short pass is allowed, but each pass individually respects the 3-question limit.

## Explicit non-goal

This does not cap `[CONTEXT-GAP]` resolution (Step 0.5/0.6, missing TDRs/ADRs) — that process already has its own per-gap structure and isn't a free-form interview; capping it would block legitimate foundational decisions. The 3-question cap applies only to intent-clarification questions about the feature itself.

code_refs:
  - "docs/tdrs/cycle-commands.md"
  - "skills/cycle-init/SKILL.md"
