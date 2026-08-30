---
name: deterministic-context-discovery
description: >-
  Fan-out search procedure over docs/adrs, docs/tdrs, docs/features, docs/business,
  and docs/ui-intent using native Read/Grep/Glob tool calls, replacing semantic/vector
  search. Used by cycle-init and cycle-run whenever context needs to be found before
  writing or evolving a spec.
when_to_use: >-
  Use whenever another skill needs to answer "was this already decided" or "which
  document governs this behavior" before proceeding. Do NOT use to search inside a
  child repo's full doc tree from a coordinator — coordinators use the scout agent
  against context-summary.yaml instead (see docs/tdrs/multi-repo-coordination.md).
---

# Skill: deterministic-context-discovery

Implements `docs/tdrs/deterministic-context-discovery.md`. No vector database, no embeddings, no MCP server — every step below uses tools already available to the host (Read, Grep, Glob, Bash `git log`).

## Procedure

1. **Decompose the query** into entities, domain terms, and technical operations implied by the request. Generate more than one phrasing per term yourself (e.g. "login" / "auth" / "sesión") — this substitutes for an embedding model; there is no separate semantic layer to call.
2. **Check `.cliplin/context-summary.yaml` first** (see `docs/tdrs/context-summary-format.md`). If a `concepts` entry matches, read its `find_via` paths directly and skip to step 5. This is the cheap path — most repeat queries should resolve here.
3. **Fan out** if step 2 found nothing conclusive: for each term, `Glob` candidate paths under `docs/adrs/`, `docs/tdrs/`, `docs/features/`, `docs/business/`, `docs/ui-intent/`, then `Grep` file content and YAML frontmatter for hits across each term phrasing.
4. **Expand one hop**: for every document matched in step 3, read any `governed_by` or cross-reference paths it lists, and check those too. Do not expand further than one hop — if the answer isn't found within one hop, it's a gap, not a deeper search.
5. **Check recency** when the query concerns "was this already decided": run `git log --since=<a reasonable window, e.g. 30 days>` filtered to the matched paths before concluding nothing exists.
6. **Classify**:
   - Clear match in one document → return it, ready to cite in `governed_by`.
   - Two matched documents contradict each other → return both, flagged as a conflict — never silently prefer one.
   - No relevant match anywhere → return empty, flagged as a gap.

## Output contract

The caller (`cycle-init` or `cycle-run`) receives one of:
- `{ result: "match", governed_by: [<paths>] }`
- `{ result: "conflict", conflicting_docs: [<paths>], description: <string> }`
- `{ result: "gap", searched_terms: [<terms>] }`

The caller decides whether a `gap`/`conflict` blocks progress (per `docs/tdrs/feature-constraints-format.md` completeness rules) — this skill does not escalate to the human itself, it only reports what it found.

## Explicit non-goals

- No ranking or relevance score — presence/absence plus the agent's own reading of content.
- No persisted index beyond `context-summary.yaml` and the filesystem itself.
- Not used for cross-repo relevance — that's the scout agent's job (`agents/scout.md`), scoped to a single small file per repo, not this fan-out procedure.
