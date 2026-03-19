#!/usr/bin/env bash
# Codex Review Gate Hook
# Two-phase model:
#   Phase 1 (first --review): requires both critic APPROVE evidence.
#   Phase 2 (re-review after codex fixes): requires codex-ran evidence (critics not re-required).
# Hard-blocks tmux-codex.sh --approve — workers cannot self-approve.
# Codex approval flows through --review-complete (verdict in findings file).
# Uses JSONL evidence log with diff_hash matching.
#
# Triggered: PreToolUse on Bash tool
# Fails open on errors (cannot determine session_id or command → allow)

source "$(dirname "$0")/lib/evidence.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Fail open if we can't parse input
if [ -z "$SESSION_ID" ] || [ -z "$COMMAND" ]; then
  echo '{}'
  exit 0
fi

# Only gate tmux-codex.sh invocations
if ! echo "$COMMAND" | grep -qE '(^|[;&|] *)([^ ]*/)?tmux-codex\.sh'; then
  echo '{}'
  exit 0
fi

# Gate 2: --approve is BLOCKED — only Codex can approve (via verdict in findings file)
# Workers must use --review-complete <findings_file>, which reads the verdict Codex wrote.
if echo "$COMMAND" | grep -qE 'tmux-codex\.sh +--approve'; then
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: --approve is forbidden. Codex approval flows through --review-complete, which reads the verdict from the findings file Codex wrote. Do not self-approve."
  }
}
EOF
  exit 0
fi

# Gate 1: --review requires evidence (not --prompt or verdict modes)
if ! echo "$COMMAND" | grep -qE 'tmux-codex\.sh +--review( |[;&|]|$)'; then
  echo '{}'
  exit 0
fi

# Two-phase gate:
# - Phase 1 (first review): both critics must APPROVE at current hash
# - Phase 2 (re-review after codex fixes): codex previously reviewed, AND critics
#   approved at the SAME hash codex first reviewed. This proves critics and codex
#   reviewed the same code — subsequent changes are codex-fix iterations only.
CWD=$(_resolve_cwd "$SESSION_ID" "$CWD")
EVIDENCE_FILE=$(evidence_file "$SESSION_ID")
CODEX_REVIEW_HASH=""
if [ -f "$EVIDENCE_FILE" ]; then
  # Find the hash of the first codex-ran entry (when codex first reviewed)
  CODEX_REVIEW_HASH=$(jq -r 'select(.type == "codex-ran") | .diff_hash' "$EVIDENCE_FILE" 2>/dev/null | head -1)
fi

if [ -n "$CODEX_REVIEW_HASH" ]; then
  # Phase 2: codex already reviewed. Verify critics approved at the same hash
  # codex first reviewed (proving both phases covered the same code).
  if jq -e --arg hash "$CODEX_REVIEW_HASH" \
    'select(.type == "code-critic" and .diff_hash == $hash)' "$EVIDENCE_FILE" >/dev/null 2>&1 && \
     jq -e --arg hash "$CODEX_REVIEW_HASH" \
    'select(.type == "minimizer" and .diff_hash == $hash)' "$EVIDENCE_FILE" >/dev/null 2>&1; then
    echo '{}'
    exit 0
  fi
  # Critics didn't approve at the same hash codex reviewed — fall through to phase 1
fi

# Phase 1: first review — require both critic APPROVE evidence
MISSING=$(check_all_evidence "$SESSION_ID" "code-critic minimizer" "$CWD" 2>&1 || true)

if [ -n "$MISSING" ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Codex review gate (phase 1) — critic APPROVE evidence missing:$MISSING. Re-run critics before first codex review."
  }
}
EOF
  exit 0
fi

# Phase 1 evidence present — allow first review
echo '{}'
