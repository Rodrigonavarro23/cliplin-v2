<!-- Written by Cliplin v2 (project-init skill or install-codex.sh). Short on purpose:
     this is a pointer, not a rulebook copy. The workflow itself lives in the
     cliplin-v2 plugin skills and in this project's own TDRs/ADRs. -->

## Cliplin v2

This project is spec-first: behavior lives in `docs/features/*.feature`, technical
rules in `docs/tdrs/*.md`, and architecture rationale in `docs/adrs/*.md` and
`docs/business/*.md`. Code is an output of those specs, not the source of truth.

### Routing (apply to every request)

1. **Behavior-affecting** (adds, changes or removes what the system does):
   - No `.feature` with an approved `@constraints` block yet → use the `cycle-init`
     skill first. No code before that.
   - Approved `.feature` exists → use the `cycle-run` skill (max 3 scenarios per
     session, closes with `cycle-validate`).
2. **Not behavior-affecting** (reading, explaining, debugging without a behavior
   change, running tests, non-functional cleanup) → proceed normally.
3. Unsure which category applies → ask. Never guess silently in either direction.

### Context lookup

Before deciding whether something was already specified, check
`.cliplin/context-summary.yaml`, then follow the `deterministic-context-discovery`
procedure (grep/glob/read over `docs/`). No vector DB, no MCP server.

### Other skills

- `reverse-engineer` — bootstrap baseline specs from existing code (only on explicit
  human request).
- `knowledge-bundle` — install/update git-sourced TDR/ADR packages under
  `.cliplin/knowledge/`.

When coordination across git submodules is required, delegate with the scoped roles
described by the plugin's `scout` and `cycle-worker` agents.
