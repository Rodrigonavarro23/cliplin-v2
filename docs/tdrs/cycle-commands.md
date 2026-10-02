---
tdr: "1.0"
id: "cycle-commands"
title: "Cycle Commands — ACD Vocabulary Native to Cliplin v2"
summary: "Maps ACD skills (acd-spec-cycle, acd-session, acd-commit-validator) to native Cliplin v2 skills (cycle-init, cycle-run, cycle-validate). Procedural content is adapted from the referenced ACD TDRs, not copied verbatim or edited in place."
---

# rules

## Resolution note (why this file exists)

This project uses its own vocabulary (`cycle-init`, `cycle-run`, `cycle-validate`) rather than the ACD names used by other agent-delivery frameworks (`acd-spec-cycle`/`acd-session`/`acd-commit-validator`) — this project's skills are authored fresh under the new names, self-contained, not dependent on any external package at runtime.

## Vocabulary mapping

| ACD skill (reference, external) | Cliplin v2 skill (this project) | Change from reference |
|---|---|---|
| `acd-spec-cycle` (authorship mode) | `cycle-init` | Unified with evolution mode — mode is detected, not chosen (see below) |
| `acd-spec-cycle` (evolution mode) | `cycle-init` (same skill, same detection) | Unified — no separate `cycle-evolve` |
| `acd-session` | `cycle-run` | Same session rules (size limits, TDD, escalation triggers) — see `acd-session-workflow.md` (reference) |
| `acd-commit-validator` | `cycle-validate` | Runs as the closing step **inside** `cycle-run`, not as a git pre-commit hook (deferred — see `docs/adrs/000-cliplin-v2-agent-native.md` Consequences) |

## `cycle-init` mode detection (replaces separate authorship/evolution invocation)

1. Resolve the feature slug from the request.
2. If no `.feature` file exists for that slug → **authorship**.
3. If a `.feature` file exists but has no `@constraints` block or empty `governed_by` → **authorship** (matches ACD's own authorship condition).
4. If a `.feature` file exists with an approved `@constraints` block → **evolution**.
5. Before assuming "new" (step 2), run `deterministic-context-discovery` (see `docs/tdrs/deterministic-context-discovery.md`) for related concepts under a different slug. If a plausible match is found, treat as `[AMBIGUITY]` and ask the human to confirm authorship vs. evolution of the existing file, rather than silently creating a duplicate. "Plausible match" is a qualitative judgment made by the agent reading the matched document's content — this TDR deliberately does not define a numeric similarity threshold; the agent's own reading of whether the concepts overlap is the mechanism, consistent with `docs/tdrs/deterministic-context-discovery.md`'s rejection of scored/ranked matching.

   **Calibration examples** (added after the comparative report against GitHub Spec Kit noted this judgment had no worked examples, unlike spec-kit's own good/bad example pairs for success criteria):

   - *Plausible match (ask)*: request is "add rate limiting to the login endpoint" and an existing `docs/features/auth-throttling.feature` already covers "limit repeated auth attempts per IP." Different words, same underlying concept — ask.
   - *Plausible match (ask)*: request is "let users sign cookies with a new algorithm" and an existing `docs/features/cookie-parsing.feature` exists, even if its scenarios don't mention signing yet — same subsystem, likely the right place to evolve rather than fork — ask.
   - *Not a match (proceed as new)*: request is "add rate limiting to the login endpoint" and the only related file is `docs/features/password-reset-email-throttling.feature` — same general theme (throttling) but a genuinely different flow with different actors and triggers — proceed as authorship, do not ask just because the domain word ("throttling") overlaps.
   - *Not a match (proceed as new)*: request is "let users sign cookies with a new algorithm" and the only related file is `docs/features/session-token-refresh.feature` — cookies are mentioned in both, but the behavior described is unrelated (refresh flow vs. signing algorithm) — proceed as authorship.

All other authorship/evolution rules (context loading, intent clarity assessment, context gap assessment, critique cycle, `@constraints` authoring) are defined in full in `plugins/cliplin-v2/skills/cycle-init/SKILL.md`.

## `cycle-init` workspace isolation (proposal, never automatic)

Runs once, after the feature slug and mode are known (worker Step 1) and **before any
file is written**. Purpose: keep spec and implementation work off the default branch
(the ACD reference forbids pushing directly to protected branches) without turning
this into a hard gate.

1. Not a git repo → skip silently.
2. Current branch is **not** the default branch (resolved from `origin/HEAD`, falling
   back to `main`, then `master`) and HEAD is not detached → announce the branch in
   one line and continue. No question.
3. On the default branch, or detached HEAD → propose, and wait for the answer:
   - **A — new branch** `cycle/<slug>` in the current working tree (recommended;
     uncommitted changes travel with it).
   - **B — new worktree** at `../<repo-name>-<slug>` on branch `cycle/<slug>`.
     Uncommitted changes stay in the original tree; say so. If the host has a native
     worktree tool, use it to move the session there; otherwise the agent tells the
     human to open a session in that path and re-invoke `cycle-init` — it does not
     keep writing into the original tree.
   - **C — stay** on the current branch. A legitimate human choice; record it in the
     announcement and do not ask again in this cycle.
4. `cycle/<slug>` already exists (e.g. resuming an evolution) → option A/B switch to
   it instead of creating it; never reset or force it.
5. Never stash, commit, push, or create remote branches as part of this step.
6. This proposal does not count toward the 3-question clarification cap
   (`docs/tdrs/clarification-limits.md` caps intent questions only).
7. **Coordinator**: propose once, at the coordinator root, as part of a single
   prompt. The chosen option and branch name are passed to every `cycle-worker`,
   which applies them in its own repo without asking again (same one-prompt rule as
   `docs/tdrs/multi-repo-coordination.md`). In a child repo, A and B both become a
   plain `cycle/<slug>` branch — no worktrees nested inside submodules.

This is a proposal only — not the worktree-isolation daemon set aside in
`docs/adrs/000-cliplin-v2-agent-native.md` (item 6), and not a substitute for remote
branch protection.

## `cycle-run`

Session rules, defined in full in `plugins/cliplin-v2/skills/cycle-run/SKILL.md`: session size (max 3 scenarios), TDD, escalation trigger handling, session close rules. The last step of session close is `cycle-validate` (see below), executed in the same conversation, not deferred to a git hook.

## `cycle-validate`

Runs base checks for artifact consistency and traceability (`AC-1`–`AC-4`, `TR-1`–`TR-2`), performed by the agent via Read/Grep tool calls against the working tree, not by an external script. UD checks (branch protection, CI) are out of scope until pre-commit hook is built (deferred).

If any check fails (e.g. a `governed_by` path does not exist on disk), the cycle does NOT close: the agent reports the specific failure to the human and waits. This is the same treatment as an unresolved `gap` — no automatic retry, no silent skip, no partial close. `context-summary.yaml` is not updated until the cycle actually closes.

code_refs:
  - "docs/adrs/000-cliplin-v2-agent-native.md"
  - "docs/tdrs/feature-constraints-format.md"
