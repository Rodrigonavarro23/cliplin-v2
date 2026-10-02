---
name: cycle-init
description: >-
  Single entry point for any feature request. Detects repo role (worker or
  coordinator, via .gitmodules) and feature mode (authorship or evolution, via
  .feature file state), then runs the appropriate spec cycle — producing or
  evolving a @constraints-governed .feature file. Delegates cross-repo work to
  scout and cycle-worker sub-agents when acting as coordinator.
when_to_use: >-
  Use for any new feature request, any change to an existing feature's behavior,
  or when a @constraints block is missing/incomplete. Do NOT use when the .feature
  file already has an approved @constraints block and the human only wants to
  implement — use cycle-run instead.
---

# Skill: cycle-init

Implements `docs/tdrs/cycle-commands.md` and `docs/tdrs/multi-repo-coordination.md`. Covers scenarios in `docs/features/cycle-init.feature`.

## Step -1: Check extension hooks (`before_cycle_init`)

Per `docs/tdrs/extension-hooks.md`: if `.cliplin/extensions.yml` exists and has entries under `hooks.before_cycle_init`, dispatch them (mandatory ones MUST actually run and complete before continuing; optional ones are presented to the human as available). If the file doesn't exist or has no entries here, skip silently — do not mention hooks.

## Step 0: Detect repo role

Read `.gitmodules` at the current repo root (per `docs/tdrs/multi-repo-coordination.md`):

- **Absent, or present with zero declared submodules** → you are the **worker**. Go to Step 1.
- **Present with at least one declared submodule** → you are the **coordinator**. Go to "Coordinator procedure" below.

Announce which role was detected before doing anything else.

## Coordinator procedure

Before Phase 1, run **Step 1.5 (workspace isolation)** once at the coordinator root,
using the slug resolved from the request, folded into the first prompt you show the
human.

### Phase 1 — Scout

For every submodule declared in `.gitmodules`, spawn a `scout` sub-agent (`agents/scout.md`) scoped to that submodule's path. Collect verdicts:

- `relevant: true` → candidate for Phase 2.
- `relevant: false` → excluded, not touched.
- `relevant: null` with an `escalation_trigger` → do not resolve yourself; carry it forward to the final aggregation step below.

### Phase 2 — Full

For every repo marked `relevant: true`, spawn a `cycle-worker` sub-agent (`agents/cycle-worker.md`) scoped to that repo's path. Pass along the workspace-isolation decision from Step 1.5 (option + branch name) so the worker applies it without asking. Each one re-enters this skill from Step 0 for its own repo (recursion — a child with its own `.gitmodules` becomes a coordinator in turn).

### Aggregation

1. Collect each worker's `governed_by`, drafted/evolved scenarios, and any unresolved `gaps`/`conflicts`/`escalation_triggers`.
2. Write cross-cutting `@constraints` in the coordinator's own `.feature` file (use `templates/feature.template.feature`) — only the parts that don't belong to a single child repo: the rationale for coordinating, and references to each child's own governing docs by path. Do not duplicate a child's content.
3. If any escalation items were collected from scouts or workers, present them to the human in **one combined prompt** — never escalate per-child.
4. Proceed only after the human resolves the combined escalation (or confirms there's nothing to resolve).

## Step 1 (worker path): Detect feature mode

1. Resolve the feature slug from the request.
2. No `.feature` file exists for that slug → tentatively **authorship**.
3. A `.feature` file exists but has no `@constraints` block, or `governed_by` is empty → **authorship**.
4. A `.feature` file exists with an approved `@constraints` block → **evolution**.
5. **Before finalizing "authorship"** (case 2): invoke `deterministic-context-discovery` (`skills/deterministic-context-discovery/SKILL.md`) searching for the request's concepts under other slugs. If a plausible match is found (qualitative judgment — no numeric threshold, per `docs/tdrs/cycle-commands.md`), do NOT create a new file. Ask the human: "Found `<existing-file>` covering a related concept — is this the same feature (evolution) or genuinely new?" Proceed only after they answer.

Announce the detected mode before proceeding.

## Step 1.5: Workspace isolation (before writing anything)

Per `docs/tdrs/cycle-commands.md` ("workspace isolation"). Skip silently outside a git
repo. If you are a `cycle-worker` and the coordinator passed an isolation decision,
apply it here without asking.

1. Resolve the default branch: `git symbolic-ref --short refs/remotes/origin/HEAD`
   (strip `origin/`), else `main`, else `master`. Read the current branch with
   `git branch --show-current` (empty = detached HEAD).
2. Current branch is set and differs from the default → announce
   "Working on branch `<branch>`." and go on. No question.
3. Otherwise propose, then wait:
   > "You're on `<default>`. Isolate this cycle?
   > A) new branch `cycle/<slug>` here (recommended — uncommitted changes come along)
   > B) new worktree `../<repo>-<slug>` on `cycle/<slug>` (uncommitted changes stay here)
   > C) stay on `<default>`"
   - A → `git switch cycle/<slug>` if it exists, else `git switch -c cycle/<slug>`.
   - B → `git worktree add ../<repo>-<slug> cycle/<slug>` if the branch exists, else
     `git worktree add -b cycle/<slug> ../<repo>-<slug>`. Move the session there with
     the host's native worktree tool if it has one; otherwise tell the human to open a
     session in that path and re-run `cycle-init`, and stop here.
   - C → note "staying on `<default>` by choice" and do not ask again this cycle.
4. Never stash, commit, push or create remote branches here. Never reset or force an
   existing `cycle/<slug>`.
5. This question does not count toward the 3-question clarification cap.

**Coordinator**: run this once at the coordinator root (fold it into the first prompt
you show the human) and pass the chosen option + branch name to every `cycle-worker`.
Workers apply A or B as a plain `cycle/<slug>` branch in their own repo (no nested
worktrees inside submodules), and C as "stay".

## Step 2: Authorship mode

1. **Context loading**: invoke `deterministic-context-discovery` for the feature's domain terms. Do not proceed on assumptions the discovery pass didn't confirm.
2. **Intent clarity assessment**: can you write at least one Given/When/Then without inventing anything the human hasn't confirmed? If the loaded context resolves the apparent ambiguity, intent is clear. Otherwise, run a short interview:
   - Phase 1 (framing): restate your understanding + what the loaded context already shows; ask one open question about the observable outcome.
   - Phase 2 (deep-dive): **maximum 3 questions** (per `docs/tdrs/clarification-limits.md`), ordered by impact — scope/boundaries first, then security/privacy, then user experience/observable behavior, then technical details. If more than 3 candidate questions exist, ask only the top 3 and make informed default assumptions for the rest, documented explicitly (not silently).
   - Phase 3 (synthesis): propose the `Feature:` description + one tentative scenario; wait for explicit human confirmation. This confirmed block is human-owned from here on — never rewrite it.
3. **Context gap assessment**: ask "what technical/business decisions must already exist for this to be implemented correctly?" For each, check via `deterministic-context-discovery` whether a governing TDR/ADR exists. Missing ones are `[CONTEXT-GAP]`s. (Not subject to the 3-question cap above — that cap is for intent clarification only, per `docs/tdrs/clarification-limits.md`.)
4. **Resolve gaps** (if any): for each `[CONTEXT-GAP]`, propose the missing TDR/ADR (using `templates/tdr.template.md` or `templates/adr.template.md`), marked as a proposal, get human approval, write it, and re-run discovery before continuing.
5. **Draft scenarios**: using `templates/feature.template.feature`, propose scenarios beneath the confirmed `Feature:` block. If any scenario is agent-proposed beyond what the human explicitly asked, tag it `@type:main`/`@type:edge`/`@type:complementary` with a `# why:` comment citing the source. If a scenario is independently testable/deliverable on its own, also tag `@priority:P1`/`P2`/`P3` per `docs/tdrs/scenario-priority.md` (untagged defaults to P2 — tagging every scenario is optional).
6. **Quality checklist** (per `docs/tdrs/spec-quality-checklist.md`): validate the draft against the checklist (no leaked implementation detail, every scenario has concrete Given/When/Then, independently testable, constraints fields non-empty/explicit). Self-correct directly on any failure — this is the agent's own responsibility, not a human decision point. Re-check. Maximum 3 iterations; if still failing, document remaining issues in the checklist file and carry them into the critique report below rather than looping forever.
7. **Critique**: review the draft against loaded context for `[CONTEXT-GAP]`, `[GAP]`, `[CONFLICT]`, `[AMBIGUITY]` items. Do not edit the file in this step — only produce the report.
8. **Human decides**: wait for explicit accept/reject/modify on every `[CONTEXT-GAP]`/`[GAP]`/`[CONFLICT]` item. `[AMBIGUITY]` may be deferred if the human says so.
9. **Refine**: apply accepted resolutions, then write the `@constraints` block per `docs/tdrs/feature-constraints-format.md` (`governed_by`, `conflicts`, `gaps`, `escalation_triggers`).

## Step 3: Evolution mode

1. Load context (`deterministic-context-discovery`) and re-read the existing `.feature` file including its `@constraints`.
2. Summarize the baseline to the human: `governed_by` list, scenario counts by status.
3. Human describes the delta; classify it (new / modified / deprecated scenario, or governing-doc change).
4. Propose the delta only — do not touch scenarios outside it.
5. Critique the delta only against the baseline (trusted, not re-critiqued).
6. Human decides on delta items.
7. Apply the delta with correct status tags (`@status:new`/`@status:modified` + `@changed:YYYY-MM-DD` + `@reason:...`, or `@status:deprecated`). Update `@constraints` only where the delta requires it.

## Handoff

After either mode (worker path) or aggregation (coordinator path) completes:

1. Check extension hooks (`after_cycle_init`) per `docs/tdrs/extension-hooks.md` — same dispatch rules as Step -1, mandatory ones must actually run.
2. Announce:

> "The ADC is complete. `governed_by` references [list]. Shall I proceed with `cycle-run`?"

Do not begin implementation without explicit human confirmation.
