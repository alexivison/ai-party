#!/usr/bin/env bash
# party-lib.sh — DEPRECATED: All functionality has been absorbed into party-cli (Go).
#
# This file is retained only for backward compatibility with any external scripts
# that may source it. All functions now delegate to party-cli or provide minimal
# shell-only fallbacks.
#
# Migration guide:
#   party-lib.sh function          → party-cli equivalent
#   discover_session()             → party-cli discover (internal)
#   write_codex_status()           → party-cli (internal to transport)
#   party_attach()                 → party-cli continue --attach <session>
#   party_is_master()              → party-cli status <session>
#   tmux_send()                    → party-cli relay / notify (internal)
#   party_role_pane_target()       → party-cli (internal tmux.ResolveRole)
#   party_codex_pane_target()      → party-cli (internal)
#   party_resolve_cli_bin()        → just use party-cli directly

# Minimal path helpers (used by some external scripts).
party_state_root() {
  printf '%s\n' "${PARTY_STATE_ROOT:-$HOME/.party-state}"
}

party_state_file() {
  local session="${1:?Usage: party_state_file SESSION_NAME}"
  printf '%s/%s.json\n' "$(party_state_root)" "$session"
}

party_runtime_dir() {
  local session="${1:?Usage: party_runtime_dir SESSION_NAME}"
  printf '/tmp/%s\n' "$session"
}

# Resolve party-cli as an array-safe command for CLI delegation.
party_resolve_cli_bin() {
  PARTY_CLI_CMD=()
  if command -v party-cli &>/dev/null; then
    PARTY_CLI_CMD=(party-cli)
    return 0
  fi
  local _repo_root
  _repo_root="${PARTY_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)}"
  if command -v go &>/dev/null && [[ -f "$_repo_root/tools/party-cli/main.go" ]]; then
    PARTY_CLI_CMD=(env "PARTY_REPO_ROOT=$_repo_root" go -C "$_repo_root/tools/party-cli" run .)
    return 0
  fi
  echo "Error: party-cli not found. Build with: cd tools/party-cli && go install ." >&2
  return 1
}
