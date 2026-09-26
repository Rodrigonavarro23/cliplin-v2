#!/usr/bin/env bash
# Cliplin v2 — Codex installer and project-briefing writer.

set -euo pipefail

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SRC_DIR="$REPO_DIR/plugins/cliplin-v2"

usage() {
  echo "Usage:" >&2
  echo "  bash install-codex.sh --marketplace        Install through Codex's local marketplace" >&2
  echo "  bash install-codex.sh /path/to/project     Write or merge AGENTS.md" >&2
  exit 1
}

[ $# -eq 1 ] || usage

if [ "$1" = "--marketplace" ]; then
  command -v codex >/dev/null 2>&1 || {
    echo "Error: codex is not available on PATH." >&2
    exit 1
  }
  codex plugin marketplace add "$REPO_DIR"
  codex plugin add "cliplin-v2@cliplin"
  echo "Cliplin v2 installed for Codex from the local marketplace."
  echo "Start a new Codex session to pick up the installed skills."
  exit 0
fi

TARGET="$1"
if [ ! -d "$TARGET" ]; then
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi

AGENTS_MD="$TARGET/AGENTS.md"
TEMPLATE="$SRC_DIR/templates/agents-md.template.md"

if [ -f "$AGENTS_MD" ]; then
  if grep -q "^## Cliplin v2$" "$AGENTS_MD" 2>/dev/null; then
    echo "$AGENTS_MD already has a Cliplin v2 section — leaving it as-is."
  else
    printf '\n' >> "$AGENTS_MD"
    cat "$TEMPLATE" >> "$AGENTS_MD"
    echo "Appended a Cliplin v2 section to existing $AGENTS_MD"
  fi
else
  cp "$TEMPLATE" "$AGENTS_MD"
  echo "Wrote $AGENTS_MD"
fi

echo "Codex will load this on the next session in $TARGET."
