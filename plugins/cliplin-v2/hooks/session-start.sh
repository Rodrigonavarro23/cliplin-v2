#!/usr/bin/env bash
# Cliplin v2 plugin — session start announcement.
# Per docs/tdrs/plugin-packaging.md: plain shell, no compiled binary, no MCP registration.

cat <<'EOF'
CLIPLIN V2 PLUGIN ACTIVE

Framework: agent-native spec-first development (ACD is the default cycle, not an optional package)
Context: deterministic discovery via grep/glob/read — no vector DB, no MCP server required

Skills available:
  cycle-init                     — single entry point: detects repo role (worker/coordinator via
                                    .gitmodules) and feature mode (authorship/evolution), produces
                                    or evolves the @constraints-governed .feature file
  cycle-run                      — implements an approved cycle (max 3 scenarios), closes with
                                    cycle-validate inline
  deterministic-context-discovery — grep/glob fan-out procedure used by the skills above
  context-summary-sync           — regenerates .cliplin/context-summary.yaml at cycle close
  project-init                   — adopts this repo: AGENTS.md briefing, CLAUDE.md import,
                                    default `cliplin` main-thread agent, docs/ scaffold
  reverse-engineer               — bootstraps baseline specs from existing code (on request)
  knowledge-bundle               — installs git-sourced TDR/ADR packages

Mandatory before any task:
  1. cycle-init reads .gitmodules first — no mode flag, ever
  2. cycle-init checks .cliplin/context-summary.yaml before a full discovery pass
  3. Never start cycle-run without a complete @constraints block (governed_by non-empty)
  4. See docs/adrs/000-cliplin-v2-agent-native.md for the full rationale
EOF

# Nudge toward project-init when the current repo hasn't adopted Cliplin yet.
if ! grep -qs '^## Cliplin v2$' "$PWD/AGENTS.md"; then
  echo
  echo "This repo has no Cliplin briefing in AGENTS.md — run the project-init skill to adopt it."
fi
