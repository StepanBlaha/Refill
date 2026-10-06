#!/bin/zsh
# Log another Codex account into its own home; Refill auto-detects ~/.codex-*.
# Usage: scripts/add-codex-account.sh work
set -euo pipefail
name="${1:?usage: add-codex-account.sh <name>}"
dir="$HOME/.codex-$name"
mkdir -p "$dir"
echo "Opening Codex with CODEX_HOME=$dir — sign in, use it once, then quit."
echo "Tip: alias codex-$name='CODEX_HOME=$dir codex'"
echo "The default ~/.codex stays the account id codex:default."
export CODEX_HOME="$dir"
codex login
codex
