<!-- Written by install.sh — see docs/tdrs/project-briefing.md. Short on purpose: this is a
     pointer, not a rulebook copy. The real rules live in this project's own TDRs/ADRs and
     in the cliplin-v2 plugin's skills. -->

## Cliplin v2

This project is spec-first: behavior lives in `docs/features/*.feature`, technical rules in `docs/tdrs/*.md`, architecture rationale in `docs/adrs/*.md` and `docs/business/*.md`. Code is an output of those specs, not the source of truth.

**Before implementing new or changed behavior**: invoke `cycle-init` first — it detects whether this is a new feature or an evolution of an existing one, and won't let you skip the `@constraints` block (which docs govern this, what's unresolved).

**Implementing an already-approved feature**: go straight to `cycle-run`.

**Fast lookup for "was this already decided"**: check `.cliplin/context-summary.yaml` before searching the full `docs/` tree.

Full rationale: see this project's `docs/adrs/` (start with the framework-adoption ADR if one exists) and `docs/business/*.md`.
