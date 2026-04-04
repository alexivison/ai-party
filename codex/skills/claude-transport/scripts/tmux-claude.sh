#!/usr/bin/env bash
# tmux-claude.sh — Backward-compatibility shim. Delegates to party-cli notify.
# New code should call party-cli notify directly.
set -euo pipefail

MESSAGE="${1:?Usage: tmux-claude.sh \"message for Claude\"}"

if command -v party-cli &>/dev/null; then
  exec party-cli notify "$MESSAGE"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${PARTY_REPO_ROOT:-$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd)}"
if command -v go &>/dev/null && [[ -f "$REPO_ROOT/tools/party-cli/main.go" ]]; then
  exec env "PARTY_REPO_ROOT=$REPO_ROOT" go -C "$REPO_ROOT/tools/party-cli" run . notify "$MESSAGE"
fi

echo "Error: party-cli not found. Build with: cd tools/party-cli && go install ." >&2
exit 1
