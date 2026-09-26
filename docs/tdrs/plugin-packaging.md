---
tdr: "1.0"
id: "plugin-packaging"
title: "Plugin Packaging — Dual Host, No Binaries or Compiled CLI"
summary: "File layout for distributing one Cliplin v2 payload to Claude Code and Codex: host manifests plus shared skills, agents, templates and shell resources."
---

# rules

## Constraint (MUST follow)

No file under this plugin's tree may be a compiled binary or require a build step (no `cargo build`, no `pip install` of a project-owned package, no per-OS artifact). Every file is plain text: Markdown (skills, agents), JSON (manifest), YAML (templates), or POSIX shell (hooks) using only tools assumed present on a developer machine (`bash`, `grep`, `git`).

This rules out per-architecture compiled binaries and any hook that registers a binary MCP server — patterns that add real deployment weight for content whose actual value is text.

## Layout

```
cliplin/
├── .codex-plugin/
│   └── plugin.json                    # Codex identity and skills discovery
├── .claude-plugin/
│   └── plugin.json                   # manifest: name, description, version, author ONLY — no hooks here
├── skills/
│   ├── cycle-init/SKILL.md
│   ├── cycle-run/SKILL.md
│   ├── deterministic-context-discovery/SKILL.md
│   └── context-summary-sync/SKILL.md
├── agents/
│   ├── scout.md
│   └── cycle-worker.md
├── hooks/
│   ├── hooks.json                    # event handler registration — this is what Claude Code reads
│   └── session-start.sh              # announces framework active; no MCP registration
└── templates/
    ├── feature.template.feature
    ├── adr.template.md
    ├── tdr.template.md
    └── context-summary.template.yaml
```

## `plugin.json` rules

- `plugin.json` declares identity only (`name`, `description`, `version`, `author`) — it does NOT declare hooks inline. This was corrected after a real failure: an earlier revision put `hooks.SessionStart` directly in `plugin.json`, which does not match Claude Code's actual plugin schema and silently failed to register (confirmed against the official plugin docs, not assumed).
- No `.mcp.json` — this plugin does not register an MCP server (see `docs/tdrs/deterministic-context-discovery.md`).

The Codex manifest lives separately at `.codex-plugin/plugin.json` and declares the
shared `./skills/` path. Neither host manifest replaces or embeds the other. See
`docs/tdrs/multi-host-plugin-packaging.md` for marketplace and installer adapters.

## `hooks/hooks.json` rules (MUST follow — corrects an earlier mistake)

- Hooks live in `hooks/hooks.json` at the plugin root, never inside `.claude-plugin/`, never inline in `plugin.json`. Schema: `{"hooks": {"<EventName>": [{"hooks": [{"type": "command", "command": "..."}]}]}}`.
- The command MUST be a shell script under `hooks/`, never a compiled binary path. Reference it via `${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh` so the path resolves regardless of where the plugin is installed.

## Skills vs. agents

- `skills/<name>/SKILL.md`: procedures the host's own model follows when triggered (mirrors the `.claude/skills/<skill>/SKILL.md` layout Claude Code itself uses for skill discovery).
- `agents/<name>.md`: sub-agent definitions (system prompt + scope) spawned via the host's native Agent/Task tool, not a separate process.

code_refs:
  - "docs/adrs/000-cliplin-v2-agent-native.md"
