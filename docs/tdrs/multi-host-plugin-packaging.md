---
tdr: "1.0"
id: "multi-host-plugin-packaging"
title: "Multi-host Plugin Packaging — Shared Payload, Host-specific Adapters"
summary: "Claude Code and Codex load one canonical skills/templates/agents payload from plugins/cliplin-v2; each host gets only its own manifest, marketplace and installer adapter."
---

# rules

## Shared payload

`plugins/cliplin-v2/` is the single distributable plugin root. Skills, agent prompts,
templates and shell resources MUST NOT be copied into host-specific trees. A workflow
change is authored once and is therefore observed by both hosts.

## Host adapters

- Claude Code identity remains in `plugins/cliplin-v2/.claude-plugin/plugin.json` and
  its marketplace remains `.claude-plugin/marketplace.json`.
- Codex identity lives in `plugins/cliplin-v2/.codex-plugin/plugin.json` and its
  marketplace lives in `.agents/plugins/marketplace.json`.
- Both marketplace entries resolve to `./plugins/cliplin-v2`.
- `install-claude.sh` and `install-codex.sh` own host-specific CLI commands.
  `install.sh` remains a compatibility entry point for the original Claude flow.

## Codex execution mapping

- Codex discovers the canonical `skills/` tree through the `skills` field in its
  plugin manifest.
- Native filesystem and shell tools satisfy the procedures described as
  Read/Grep/Glob/Bash in the shared skills; those names describe capabilities, not
  a required tool API.
- `agents/scout.md` and `agents/cycle-worker.md` are portable role prompts. A host
  with native sub-agent support dispatches those roles using its own delegation
  mechanism; the files MUST NOT prescribe a Claude CLI subprocess.
- The Claude `SessionStart` hook is a host enhancement, not a prerequisite of the
  harness. Codex may run the skills without reproducing the banner.
- Project-wide persistent guidance uses `CLAUDE.md` in Claude Code and `AGENTS.md`
  in Codex; their installers MUST preserve existing files and append a delimited
  Cliplin section rather than overwrite user instructions.

## Explicit exclusions

The repository-root `.mcp.json` is legacy project configuration and is not declared
by either plugin manifest. Cliplin v2 does not require MCP, a compiled binary or a
separate runtime in either host.

code_refs:
  - ".agents/plugins/marketplace.json"
  - "plugins/cliplin-v2/.codex-plugin/plugin.json"
  - "install-claude.sh"
  - "install-codex.sh"
