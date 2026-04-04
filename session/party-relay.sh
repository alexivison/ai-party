#!/usr/bin/env bash
# party-relay.sh — Backward-compatibility shim. Delegates to party-cli.
# New code should call party-cli directly.
set -euo pipefail

if command -v party-cli &>/dev/null; then
  CLI=(party-cli)
elif command -v go &>/dev/null; then
  repo_root="${PARTY_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)}"
  if [[ -f "$repo_root/tools/party-cli/main.go" ]]; then
    CLI=(env "PARTY_REPO_ROOT=$repo_root" go -C "$repo_root/tools/party-cli" run .)
  fi
fi

if [[ ${#CLI[@]} -eq 0 ]]; then
  echo "Error: party-cli not found. Build with: cd tools/party-cli && go install ." >&2
  exit 1
fi

case "${1:-}" in
  --broadcast) exec "${CLI[@]}" broadcast "${2:?--broadcast requires a message}" ;;
  --read)
    shift; worker="${1:?--read requires a worker ID}"; shift
    lines=50
    [[ "${1:-}" == "--lines" ]] && { lines="${2:?--lines requires a number}"; shift 2; }
    exec "${CLI[@]}" read "$worker" --lines "$lines"
    ;;
  --report) exec "${CLI[@]}" report "${2:?--report requires a message}" ;;
  --list) exec "${CLI[@]}" workers ;;
  --stop) exec "${CLI[@]}" stop "${2:?--stop requires a worker ID}" ;;
  --spawn) shift; exec "${CLI[@]}" spawn "$@" ;;
  --file)
    shift; path="${1:?--file requires a path}"; worker="${2:?--file requires a worker ID}"
    exec "${CLI[@]}" relay --file "$path" "$worker"
    ;;
  --wizard)
    shift; worker="${1:?--wizard requires a worker ID}"; msg="${2:?--wizard requires a message}"
    exec "${CLI[@]}" relay --wizard "$worker" "$msg"
    ;;
  --help|-h)
    echo "Usage: party-relay.sh <worker-id> \"message\" | --broadcast | --read | --report | --list | --stop | --spawn | --file | --wizard"
    ;;
  *)
    [[ $# -lt 2 ]] && { echo "Usage: party-relay.sh <worker-id> \"message\"" >&2; exit 1; }
    exec "${CLI[@]}" relay "$1" "$2"
    ;;
esac
