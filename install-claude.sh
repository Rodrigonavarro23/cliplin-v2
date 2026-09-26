#!/usr/bin/env bash
# Cliplin v2 — Claude Code installer and project-briefing writer.

set -euo pipefail

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SRC_DIR="$REPO_DIR/plugins/cliplin-v2"
PLUGIN_NAME="cliplin-v2"

usage() {
  echo "Usage:" >&2
  echo "  bash install-claude.sh --marketplace       Install through Claude Code's local marketplace" >&2
  echo "  bash install-claude.sh --global            Install into ~/.claude/skills/cliplin-v2" >&2
  echo "  bash install-claude.sh /path/to/project     Write or merge .claude/CLAUDE.md" >&2
  exit 1
}

[ $# -eq 1 ] || usage

if [ "$1" = "--marketplace" ]; then
  command -v claude >/dev/null 2>&1 || {
    echo "Error: claude is not available on PATH." >&2
    exit 1
  }
  claude plugin marketplace add "$REPO_DIR"
  claude plugin install "cliplin-v2@cliplin"
  echo "Cliplin v2 installed for Claude Code from the local marketplace."
  exit 0
fi

if [ "$1" = "--global" ]; then
  TARGET_ROOT="$HOME/.claude/skills/$PLUGIN_NAME"
  mkdir -p "$TARGET_ROOT"

  cp -R "$SRC_DIR/.claude-plugin" "$TARGET_ROOT/.claude-plugin"
  cp -R "$SRC_DIR/skills" "$TARGET_ROOT/skills"
  cp -R "$SRC_DIR/agents" "$TARGET_ROOT/agents"
  cp -R "$SRC_DIR/hooks" "$TARGET_ROOT/hooks"
  cp -R "$SRC_DIR/templates" "$TARGET_ROOT/templates"

  echo "Cliplin v2 plugin installed at $TARGET_ROOT"
  echo "Start or restart Claude Code to pick it up."
  exit 0
fi

TARGET="$1"
if [ ! -d "$TARGET" ]; then
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi

CLAUDE_MD="$TARGET/.claude/CLAUDE.md"
TEMPLATE="$SRC_DIR/templates/claude-md.template.md"

mkdir -p "$TARGET/.claude"

if [ -f "$CLAUDE_MD" ]; then
  if grep -q "^## Cliplin v2$" "$CLAUDE_MD" 2>/dev/null; then
    echo "$CLAUDE_MD already has a Cliplin v2 section — leaving it as-is."
  else
    printf '\n' >> "$CLAUDE_MD"
    cat "$TEMPLATE" >> "$CLAUDE_MD"
    echo "Appended a Cliplin v2 section to existing $CLAUDE_MD"
  fi
else
  cp "$TEMPLATE" "$CLAUDE_MD"
  echo "Wrote $CLAUDE_MD"
fi

echo "Claude Code will load this on the next session in $TARGET."
