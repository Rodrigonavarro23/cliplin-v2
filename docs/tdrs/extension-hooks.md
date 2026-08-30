---
tdr: "1.0"
id: "extension-hooks"
title: "Extension Hooks — Third-Party Behavior Without Editing Core Skills"
summary: "Declarative hooks at 4 points (before/after cycle-init, before/after cycle-run) via .cliplin/extensions.yml, dispatching either skills or plain shell scripts. Adapted from GitHub Spec Kit's before_specify/after_specify hook pattern, simplified because this project has no CLI/binary executor — the agent itself evaluates conditions."
---

# rules

## Resolution note (why this file exists, and what's different from the reference)

The comparative report against GitHub Spec Kit (2026-07-13) found their `.specify/extensions.yml` hook system (`hooks.before_specify`/`hooks.after_specify`) a real gap in Cliplin v2 — no place for a team to bolt on custom behavior (e.g. a security-review pass after every cycle) without editing the core skills directly.

One deliberate difference from the reference: spec-kit's hook conditions are evaluated by their Python CLI's `HookExecutor` — they explicitly tell the agent "do not attempt to interpret condition expressions, leave it to the HookExecutor." This project has no CLI/binary (`docs/tdrs/plugin-packaging.md`), so there is no separate executor to defer to. Conditions here are natural-language strings evaluated by the agent's own judgment at the moment the hook point is reached — consistent with this project's whole model, where the agent already reasons about every other rule instead of a code path doing it.

## Location and schema (MUST follow)

`.cliplin/extensions.yml`, project root. Optional file — its absence means no hooks, skip silently.

```yaml
hooks:
  before_cycle_init: []
  after_cycle_init: []
  before_cycle_run: []
  after_cycle_run: []
```

Each entry:

```yaml
  - skill: <skill-name>          # preferred: invoke another skill by name
    # OR, mutually exclusive with `skill`:
    script: hooks/<name>.sh      # plain shell script only — no compiled binary (docs/tdrs/plugin-packaging.md)
    description: <string>        # shown to the human when the hook is optional
    optional: true                # default true if absent
    condition: <string, optional> # natural language; the agent judges whether it applies, no code evaluates it
    enabled: true                 # default true if absent
```

## Dispatch rules (MUST follow)

At each hook point (start of `cycle-init`, end of `cycle-init` after ADC handoff, start of `cycle-run`, end of `cycle-run` after `cycle-validate` closes):

1. Check whether `.cliplin/extensions.yml` exists. If not, or it has no entries for this hook point, skip silently — do not mention hooks to the human.
2. If the YAML is malformed, skip hook checking silently and continue normally — a broken extensions file must never block the core cycle.
3. Filter out entries with `enabled: false`.
4. For each remaining entry, if it has a `condition`, judge (as the agent, using its own reasoning — no code evaluates this) whether the condition applies given the current cycle's context. If it has no `condition`, treat it as always applicable.
5. For each applicable entry:
   - **`optional: false` (mandatory)**: you MUST actually invoke it — run the referenced skill or script and wait for it to finish before continuing. Announcing that a mandatory hook exists is not the same as running it; both must happen.
   - **`optional: true`**: present it to the human as available (name, description, how to invoke) — do not run it automatically.

## Explicit non-goals

- No hook can bypass `cycle-validate`'s persisted report requirement (`docs/tdrs/cycle-validate-report.md`) — a hook runs in addition to the core checks, never instead of them.
- No dynamic condition language (no expression grammar, no operators) — conditions are natural language for the agent to judge, deliberately, since adding a mini-language would require code this project doesn't have.
- This does not replace `reverse-engineer` or any core skill — hooks are for behavior genuinely outside this project's own scope (e.g. a team's internal security/compliance pass), not a place to relocate core ACD logic.

code_refs:
  - "docs/tdrs/plugin-packaging.md"
  - "docs/tdrs/cycle-validate-report.md"
  - "skills/cycle-init/SKILL.md"
  - "skills/cycle-run/SKILL.md"
