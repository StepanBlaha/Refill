#!/bin/zsh
# Log another Gemini CLI account into its own home.
# Gemini CLI writes creds to $GEMINI_CLI_HOME/.gemini/oauth_creds.json.
# Usage: scripts/add-gemini-account.sh work
set -euo pipefail
name="${1:?usage: add-gemini-account.sh <name>}"
dir="$HOME/.gemini-accounts/$name"
mkdir -p "$dir"
echo "Opening Gemini with GEMINI_CLI_HOME=$dir — sign in, then exit."
echo "Creds land in $dir/.gemini/oauth_creds.json"
echo "Tip: alias gemini-$name='GEMINI_CLI_HOME=$dir gemini'"
echo "The default ~/.gemini stays the account id gemini:default."
export GEMINI_CLI_HOME="$dir"
gemini
