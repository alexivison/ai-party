#!/usr/bin/env bash
# tmux-codex.sh — Backward-compatibility shim. Delegates to party-cli transport.
# New code should call party-cli transport directly.
set -euo pipefail

MODE="${1:?Usage: tmux-codex.sh --review|--plan-review|--prompt|--review-complete|--needs-discussion|--triage-override}"

if command -v party-cli &>/dev/null; then
  CLI=(party-cli)
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="${PARTY_REPO_ROOT:-$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd)}"
  if command -v go &>/dev/null && [[ -f "$REPO_ROOT/tools/party-cli/main.go" ]]; then
    CLI=(env "PARTY_REPO_ROOT=$REPO_ROOT" go -C "$REPO_ROOT/tools/party-cli" run .)
  else
    echo "Error: party-cli not found. Build with: cd tools/party-cli && go install ." >&2
    exit 1
  fi
fi

case "$MODE" in
  --review)
    shift
    exec "${CLI[@]}" transport review "$@"
    ;;
  --plan-review)
    shift
    exec "${CLI[@]}" transport plan-review "$@"
    ;;
  --prompt)
    shift
    exec "${CLI[@]}" transport prompt "$@"
    ;;
  --review-complete)
    exec "${CLI[@]}" transport review-complete "${2:?Missing findings file path}"
    ;;
  --needs-discussion)
    exec "${CLI[@]}" transport needs-discussion "${2:-}"
    ;;
  --triage-override)
    exec "${CLI[@]}" transport triage-override "${2:?Missing type}" "${3:?Missing rationale}"
    ;;
  --approve)
    echo "Error: --approve is deprecated. Use: party-cli transport review-complete <findings_file>" >&2
    exit 1
    ;;
  *)
    echo "Error: Unknown mode '$MODE'" >&2
    echo "Usage: tmux-codex.sh --review|--plan-review|--prompt|--review-complete|--needs-discussion|--triage-override" >&2
    exit 1
    ;;
esac
