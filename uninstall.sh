#!/bin/bash
# uninstall.sh — Backward-compatibility shim. Delegates to party-cli uninstall.
set -e

if command -v party-cli &>/dev/null; then
  exec party-cli uninstall "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v go &>/dev/null && [[ -f "$SCRIPT_DIR/tools/party-cli/main.go" ]]; then
  exec env "PARTY_REPO_ROOT=$SCRIPT_DIR" go -C "$SCRIPT_DIR/tools/party-cli" run . uninstall "$@"
fi

echo "Error: party-cli not found. Build with: cd tools/party-cli && go install ." >&2
exit 1
