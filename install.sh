#!/usr/bin/env bash
# Cliplin v2 — installer and project-briefing writer.
#
# Two independent things this script does, per the flag:
#   --global            Install the plugin itself, personal scope (~/.claude/skills/cliplin-v2/).
#                        Loads in every project, no trust dialog. See docs/tdrs/installation.md
#                        for why this is preferred over project-scope plugin install (marketplace
#                        install, docs/tdrs/installation.md Path 1, is preferred over both).
#   <project-path>       Write/merge a Cliplin v2 project briefing (.claude/CLAUDE.md) into that
#                        project — NOT a plugin install. Gives Claude Code baseline domain
#                        awareness on every session start in that project, no skill invocation
#                        needed. See docs/tdrs/project-briefing.md.
#
# Plain shell, no binary, no build step (docs/tdrs/plugin-packaging.md).

set -euo pipefail

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SRC_DIR="$REPO_DIR/plugins/cliplin-v2"
PLUGIN_NAME="cliplin-v2"

usage() {
  echo "Usage:" >&2
  echo "  bash install.sh --global              Install the plugin (personal scope, all projects)" >&2
  echo "  bash install.sh /path/to/project       Write a Cliplin v2 project briefing into that project" >&2
  exit 1
}

[ $# -ge 1 ] || usage

if [ "$1" = "--global" ]; then
  TARGET_ROOT="$HOME/.claude/skills/$PLUGIN_NAME"
  mkdir -p "$TARGET_ROOT"

  cp -R "$SRC_DIR/.claude-plugin" "$TARGET_ROOT/.claude-plugin"
  cp -R "$SRC_DIR/skills" "$TARGET_ROOT/skills"
  cp -R "$SRC_DIR/agents" "$TARGET_ROOT/agents"
  cp -R "$SRC_DIR/hooks" "$TARGET_ROOT/hooks"
  cp -R "$SRC_DIR/templates" "$TARGET_ROOT/templates"

  echo "Cliplin v2 plugin installed at $TARGET_ROOT"
  echo "Start (or restart) a Claude Code session anywhere to pick it up."
  exit 0
fi

TARGET="$1"
if [ ! -d "$TARGET" ]; then
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi

# --- Project briefing (docs/tdrs/project-briefing.md) ---
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

echo "Claude Code will load this automatically on the next session in $TARGET — no skill invocation needed."
