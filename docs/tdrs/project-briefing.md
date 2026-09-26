---
tdr: "1.0"
id: "project-briefing"
title: "Project Briefing — Host-native Persistent Instructions"
summary: "The host-specific installer writes project-scoped persistent guidance: CLAUDE.md for Claude Code and AGENTS.md for Codex, preserving existing instructions in either host."
---

# rules

## Resolution note (why this file exists)

The plugin is installed at personal/marketplace scope (`docs/tdrs/installation.md`) — it loads in every project the user opens, not just Cliplin-governed ones. Two mechanisms were considered for giving Claude baseline domain awareness beyond the `SessionStart` banner:

1. **A plugin-level default agent** (`settings.json`'s `agent` key, per Claude Code's plugin settings spec) — activates a custom agent as the main thread whenever the plugin is enabled. Rejected: this would override the main-thread persona in *every* project where the plugin loads, including projects that have nothing to do with Cliplin. Too invasive for a personal-scope install.
2. **A project-scoped `CLAUDE.md`** — Claude Code's own native "project instructions" mechanism, auto-loaded at session start for that specific project only, with no plugin/skill machinery involved. This project's own `.claude/CLAUDE.md` is a live example: it loads automatically in every session opened here, which is how this repository has been developed throughout.

Option 2 is adopted. It also restores the actual mechanism v1 used (`cliplin init` wrote `.claude/instructions.md`, `.claude/rules/*.md`, `.claude/claude.md` into the adopting project) — v2's `install.sh` installs the plugin itself but, until now, never wrote anything into the adopting project, leaving this gap.

## What gets written (MUST follow)

`install.sh <project-path>` (project-path form only — `--global` has no single adopting project to write into) writes `<project-path>/.claude/CLAUDE.md` from `plugins/cliplin-v2/templates/claude-md.template.md`, filled in with the project's own governing doc paths where discoverable (e.g. if `docs/adrs/` exists, reference it).

`install-codex.sh <project-path>` writes or merges `<project-path>/AGENTS.md` from
`plugins/cliplin-v2/templates/agents-md.template.md`. The semantic briefing is the
same; only the host-native filename and delegation wording differ.

**Content requirements (MUST be true of the generated file)**:
- Short. This is a pointer/briefing, not a rulebook copy — the actual rules live in the project's own TDRs/ADRs and the plugin's skills. Repeating them here would recreate the verbosity problem this project's own comparative testing found in v1's rule files.
- States: this project uses Cliplin v2, spec-first, ACD as the default flow.
- Points to the project's own `docs/adrs/000-*.md` (or equivalent) and `docs/business/*.md` for the full rationale, if those exist.
- States the one behavioral rule that actually matters at session-start time: new/changed behavior needs `cycle-init` before code; an already-approved `.feature` goes straight to `cycle-run`.
- Mentions `.cliplin/context-summary.yaml` as the fast "was this already decided" lookup.

## In-host adoption: `project-init` skill (MUST prefer this over the installer path)

A globally or marketplace-installed plugin has no project to write into, so the
installer's `<project-path>` form forced a second trip to the shell. The
`project-init` skill (`plugins/cliplin-v2/skills/project-init/SKILL.md`) does the
same adoption from inside the host:

- `AGENTS.md` is the canonical, host-neutral briefing
  (`templates/agents-md.template.md`), including the routing discipline.
- Claude Code: `CLAUDE.md` (root, or `.claude/CLAUDE.md` if that is what exists)
  gets an `@AGENTS.md` import instead of a copy — one source of truth.
- Claude Code: writes `.claude/agents/cliplin.md` from
  `templates/cliplin-agent.template.md` and sets `"agent": "cliplin"` in
  `.claude/settings.json`, per `docs/tdrs/main-thread-agent.md`.
- Scaffolds `docs/{features,tdrs,adrs,business}/` and `.cliplin/` (with
  `.gitkeep`), but never `context-summary.yaml`.
- Same merge rules as below; idempotent.

The installer `<project-path>` forms remain as a shell fallback.

## Merge behavior (MUST follow)

If `<project-path>/.claude/CLAUDE.md` already exists (the project has its own instructions for unrelated reasons), do NOT overwrite it. Append a clearly-delimited Cliplin section instead (e.g. under a `## Cliplin v2` heading), and report to the human what was appended rather than silently modifying an existing file's meaning.

Apply the identical preservation rule when `AGENTS.md` already exists.

## Explicit non-goal

This does not replace the `SessionStart` hook banner (`hooks/session-start.sh`) — the banner confirms the *plugin* is active and lists skills; `CLAUDE.md` gives *this specific project's* domain context. Both can be true at once; they answer different questions ("is Cliplin loaded" vs. "what does Cliplin mean for this repo").

code_refs:
  - "plugins/cliplin-v2/skills/project-init/SKILL.md"
  - "plugins/cliplin-v2/templates/agents-md.template.md"
  - "plugins/cliplin-v2/templates/cliplin-agent.template.md"
  - "install.sh"
  - "install-claude.sh"
  - "install-codex.sh"
  - "docs/tdrs/installation.md"
  - "docs/tdrs/plugin-packaging.md"
