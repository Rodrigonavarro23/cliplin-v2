---
tdr: "1.0"
id: "main-thread-agent"
title: "Main-Thread Agent — Project-Scoped, Not a Plugin-Level Override"
summary: "A project's own .claude/agents/cliplin.md, set as the default main-thread agent via that project's .claude/settings.json (agent key). Routes behavior-affecting requests through cycle-init/cycle-run before implementation. Scoped per-project (verified via Claude Code's settings reference), unlike a plugin-level agent override which would apply everywhere the personal-scope-installed plugin loads."
---

# rules

## Resolution note (why this exists, and how it differs from CLAUDE.md)

`docs/tdrs/project-briefing.md` (`CLAUDE.md`) gives passive context — available in the system prompt, but the model still decides whether to act on it, same enforcement category as any other instruction. This TDR adds a stronger mechanism: a **named default agent** for the project's main thread (not a sub-agent invoked on demand — the agent the human talks to directly), confirmed via Claude Code's settings reference to be settable at **project scope** specifically (`.claude/settings.json`'s `agent` key), not just plugin-wide. This resolves the scoping objection that ruled out a plugin-level agent override in `project-briefing.md`: a project-level `agent` setting only affects sessions started in that project, never other projects sharing the same personal-scope-installed plugin.

## What this does NOT do (MUST be honest about this)

This is not a mechanical tool-blocking gate. The agent definition's `tools`/`disallowedTools` fields COULD restrict Edit/Write until a cycle is active, but this TDR deliberately does not do that — blanket-restricting file-editing tools would also block legitimate non-behavior-affecting work (debugging, reading code, running tests, fixing a typo in a comment), which has nothing to do with ACD. The routing discipline below is still a system-prompt-level instruction, same enforcement category as `cycle-validate` before its mechanical report (`docs/tdrs/cycle-validate-report.md`) — stronger than `CLAUDE.md` because it's the *permanent* system prompt of the thread the human is talking to, not competing context, but not a hard technical gate. Accepted explicitly, not an oversight — consistent with this project's existing accepted-debt pattern (no pre-commit hook yet either).

## File and setting (MUST follow)

- `<project>/.claude/agents/cliplin.md` — the agent definition, project-scoped (lives in the adopting project, not the plugin — a project's routing discipline is project-specific, not something to distribute via the plugin bundle).
- `<project>/.claude/settings.json` (the shared, tracked settings file — NOT `settings.local.json`, since this is a team-standardization decision per Claude Code's own scope guidance) sets `{"agent": "cliplin"}`.

## Agent content requirements (MUST be true)

1. Classify every request as behavior-affecting or not before proceeding:
   - **Behavior-affecting** (adds/changes/removes what the system does): check for an existing `.feature` with an approved `@constraints` block. Missing or incomplete → `cycle-init` first, no code before that. Existing and approved → `cycle-run`.
   - **Not behavior-affecting** (reading, explaining, debugging without a behavior change, running tests, non-functional cleanup): proceed normally, no `cycle-init` needed.
2. When genuinely unsure which category applies, ask — never guess silently in either direction. This mirrors `docs/tdrs/clarification-limits.md`'s discipline (ask a sharp question rather than assume).
3. Keep the domain-reference portion of the system prompt aligned with `plugins/cliplin-v2/templates/claude-md.template.md` — both describe the same framework, this file adds the routing discipline on top.

## Explicit non-goal

This does not apply to sub-agents (`scout`, `cycle-worker`) — those already have narrow, single-purpose system prompts scoped to their delegated task and don't need this general routing discipline.

code_refs:
  - "docs/tdrs/project-briefing.md"
  - "docs/tdrs/cycle-commands.md"
  - "docs/tdrs/installation.md"
