<!-- Written by install-codex.sh. Short on purpose: this is a pointer, not a
     rulebook copy. The workflow itself lives in the cliplin-v2 plugin skills. -->

## Cliplin v2

This project is spec-first: behavior lives in `docs/features/*.feature`, technical
rules in `docs/tdrs/*.md`, and architecture rationale in `docs/adrs/*.md` and
`docs/business/*.md`. Code is an output of those specs, not the source of truth.

Before implementing new or changed behavior, use the `cycle-init` skill. It detects
whether the request creates or evolves a feature and requires an approved
`@constraints` governance block before implementation.

For an already-approved feature, use `cycle-run`. Before deciding whether something
was already specified, check `.cliplin/context-summary.yaml` and then follow the
deterministic context-discovery procedure.

When coordination across git submodules is required, use Codex's native sub-agent
delegation with the scoped roles described by the plugin's `agents/scout.md` and
`agents/cycle-worker.md` prompts.
