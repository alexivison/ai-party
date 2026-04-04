#!/bin/bash
# install.sh — Backward-compatibility shim. Delegates to party-cli install.
# New users should run: party-cli install
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try party-cli first.
if command -v party-cli &>/dev/null; then
  exec party-cli install "$@"
fi

# Fallback: build party-cli from source if Go is available.
if command -v go &>/dev/null && [[ -f "$SCRIPT_DIR/tools/party-cli/main.go" ]]; then
  echo "Building party-cli from source..."
  (cd "$SCRIPT_DIR/tools/party-cli" && go install .) || {
    echo "Failed to build party-cli. Install Go 1.25+ and try again." >&2
    exit 1
  }
  exec party-cli install "$@"
fi

echo "Error: party-cli not found and Go is not available to build it." >&2
echo "Install Go (brew install go), then run: cd tools/party-cli && go install ." >&2
exit 1
