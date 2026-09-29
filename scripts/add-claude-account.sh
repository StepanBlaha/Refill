#!/bin/zsh
# Log another Claude account into its own config dir; Refill auto-detects ~/.claude-*.
# Usage: scripts/add-claude-account.sh work
set -euo pipefail
name="${1:?usage: add-claude-account.sh <name>}"
dir="$HOME/.claude-$name"
mkdir -p "$dir"
echo "Opening Claude Code with CLAUDE_CONFIG_DIR=$dir — run /login, then quit."
echo "Tip: alias claude-$name='CLAUDE_CONFIG_DIR=$dir claude'"
CLAUDE_CONFIG_DIR="$dir" claude
