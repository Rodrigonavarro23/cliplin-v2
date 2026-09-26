#!/usr/bin/env bash
# Backward-compatible entry point. New integrations should choose the host-specific installer.

set -euo pipefail

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec bash "$REPO_DIR/install-claude.sh" "$@"
