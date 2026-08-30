---
tdr: "1.0"
id: "deterministic-context-discovery"
title: "Deterministic Context Discovery — No Vector DB, No MCP Server"
summary: "Context discovery for Cliplin v2 uses native Read/Grep/Glob tool calls orchestrated by a skill procedure, replacing semantic/vector search as the default mechanism."
---

# rules

## Resolution note (why this file exists, and what it supersedes)

A prior context-loading approach mandated querying an MCP server backed by a vector database (embeddings, ANN index). For this project, that mechanism is replaced entirely: no MCP server, no embeddings, no per-OS binary.

Rationale: Cliplin specs are small, structured, path-routable text files — not a large unstructured corpus. A model reasoning over grep/glob results can generate its own semantic term variants (it already knows "login" ~ "auth" ~ "sesión") without a separate embedding model. This is also strictly more deterministic: identical grep input always returns identical output, unlike embedding similarity which varies by model version and threshold.

## Procedure (MUST follow)

1. **Decompose the query** into entities, domain terms, and technical operations (e.g. file I/O → "file operations encoding"; env vars → "environment variables configuration"; HTTP calls → "HTTP client library" — map the operation to the terms most likely to appear in a governing doc about it).
2. **Check `context-summary.yaml` first** (per `docs/tdrs/context-summary-format.md`) for a matching `concepts` entry — if found, jump directly to its `find_via` paths and read those documents; skip to step 5.
3. **Fan out**: for each term, `glob` candidate paths by convention (`docs/adrs/`, `docs/tdrs/`, `docs/features/`, `docs/business/`, `docs/ui-intent/`, and — per `docs/tdrs/knowledge-bundle-management.md` — `.cliplin/knowledge/**` for installed bundles) and `grep` content and YAML frontmatter for hits. The agent SHOULD generate multiple phrasings of each term itself before searching (its own reasoning substitutes for an embedding model).
4. **Expand one hop**: for each matched document, follow any `governed_by`/cross-reference paths it lists, and check those too.
5. **Check recency**: if the query concerns "was this already decided," run `git log --since=<reasonable window>` filtered to matched paths before concluding nothing exists.
6. **Classify the result**:
   - Clear match → proceed, citing the matched doc(s) in `governed_by`.
   - Two matched docs contradict each other → record in `conflicts`, do not silently pick one.
   - No relevant match found → record in `gaps`.
7. Only escalate to the human when the resulting `gaps` or `conflicts` (per `docs/tdrs/feature-constraints-format.md`) are non-empty; otherwise proceed autonomously, citing what was found.

## Explicit non-goals

- No ranking/relevance score is computed — matches are presence/absence plus the agent's own judgment reading the content.
- No index is persisted beyond `context-summary.yaml` (concepts) and the filesystem itself (paths) — there is no separate database to keep in sync or that can go stale independently of the files it describes.
- Cross-repo relevance search is explicitly out of this TDR's scope — see `docs/tdrs/multi-repo-coordination.md` for the scout-phase mechanism, which reuses this same grep/read approach but scoped to a single small file (`context-summary.yaml`) instead of a full tree.

code_refs:
  - "docs/adrs/000-cliplin-v2-agent-native.md"
  - "docs/tdrs/context-summary-format.md"
  - "docs/tdrs/multi-repo-coordination.md"
