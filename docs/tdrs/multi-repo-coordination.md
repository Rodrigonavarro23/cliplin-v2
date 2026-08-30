---
tdr: "1.0"
id: "multi-repo-coordination"
title: "Multi-Repo Coordination — Recursive Detection via .gitmodules"
summary: "How a Cliplin v2 agent recognizes coordinator vs. worker role without a mode flag, and how cross-repo delegation works via native Agent/Task sub-agents in two phases: scout then full."
---

# rules

## Mode detection (MUST follow, no flag)

At the start of any `cycle-init` or `cycle-run`, the agent reads `.gitmodules` at the current repo root:

- **Absent** → the agent IS the worker for this repo. Proceed with the local cycle directly (see `docs/tdrs/cycle-commands.md`).
- **Present but declares zero submodules** (empty file) → treated the same as absent: the agent is the worker. An empty `.gitmodules` is not a signal to coordinate.
- **Present with at least one declared submodule** → the agent acts as coordinator for this cycle. Every submodule declared in `.gitmodules` is a candidate child repo.

This is the only signal used. There is no separate "multi-repo mode" configuration; a repo without children is simply the base case of the same recursive procedure — if children are added later (a submodule is added), the next `cycle-init` run in that repo automatically becomes a coordinator run without any change to the skill itself.

## Coordinator procedure

### Phase 1 — Scout (parallel, cheap)

For each child repo declared in `.gitmodules`:

1. Spawn a `scout` sub-agent (per `docs/tdrs/plugin-packaging.md` `plugins/cliplin-v2/agents/scout.md`), scoped to that child repo's path.
2. The scout reads ONLY that repo's `.cliplin/context-summary.yaml` (per `docs/tdrs/context-summary-format.md`) — never the full `docs/` tree, never another repo's files.
3. The scout returns: `relevant: true|false`, and if true, the matched `concepts` entries with their `find_via` pointers.

If a declared submodule has no `.cliplin/context-summary.yaml` (it never ran a cycle), the scout MUST NOT default to `relevant: false`. This is an `escalation_trigger` (see `docs/tdrs/feature-constraints-format.md`) — the coordinator reports it to the human instead of silently skipping an uninitialized repo. The report MUST be actionable, not generic: it recommends running `reverse-engineer` (see `docs/tdrs/reverse-engineering.md`) on that specific repo. The coordinator never runs `reverse-engineer` automatically — it presents the recommendation and waits; the human may decline and let `cycle-worker` proceed without a baseline.

The coordinator collects these verdicts. It does not itself interpret any child repo's content — judgment about relevance to that repo's domain is made only by the scout scoped to it.

### Phase 2 — Full (only for relevant repos)

For each child repo marked relevant in Phase 1:

1. Spawn a `cycle-worker` sub-agent (per `docs/tdrs/plugin-packaging.md` `plugins/cliplin-v2/agents/cycle-worker.md`), scoped to that child repo's path.
2. That sub-agent re-enters this same procedure from the top (mode detection) — recursion: if the child itself declares further submodules, it becomes a coordinator in turn; otherwise it proceeds as worker running its own local `cycle-init`/`cycle-run`.

### Aggregation

The coordinator writes cross-cutting `@constraints` in the central repo's own feature file — only the parts that do not belong to a single child repo (rationale for coordinating across repos, links to each child's own decisions). It does NOT duplicate content that a child repo's own `.feature`/TDR/ADR already owns; it references it by path (submodule-relative).

## Escalation aggregation

If any child worker's cycle produces unresolved `gaps` or `conflicts` (per `docs/tdrs/feature-constraints-format.md`), the coordinator collects them and escalates to the human in a single combined prompt, rather than each child escalating independently — avoids multiple separate interruptions for one feature request.

## Sub-agent dispatch mechanism (MUST follow)

Delegation uses the host's native Agent/Task tool to spawn sub-agents scoped to a given repo path. This project does NOT spawn headless CLI subprocesses for this interactive case — that pattern is reserved for a future unattended/CI mode, out of scope here.

code_refs:
  - "docs/adrs/000-cliplin-v2-agent-native.md"
  - "docs/tdrs/context-summary-format.md"
  - "docs/tdrs/cycle-commands.md"
