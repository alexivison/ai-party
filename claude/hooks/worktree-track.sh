#!/usr/bin/env bash
# Worktree Track Hook
# Automatically writes the worktree override file when `git worktree add` succeeds.
# This enables evidence.sh _resolve_cwd() to use the correct worktree path
# even when hook input carries the main repo cwd.
#
# Triggered: PostToolUse on Bash tool

source "$(dirname "$0")/lib/evidence.sh"

hook_input=$(cat)

command=$(echo "$hook_input" | jq -r '.tool_input.command // ""' 2>/dev/null)
session_id=$(echo "$hook_input" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$session_id" ] || [ -z "$command" ]; then
  hook_log "worktree-track" "${session_id:-unknown}" "allow" "missing session_id or command — fail open"
  echo '{}'
  exit 0
fi

# Only detect git worktree add commands — pass-through not logged (high frequency)
if ! echo "$command" | grep -qE 'git worktree add '; then
  echo '{}'
  exit 0
fi

# Verify the command succeeded
exit_code=$(echo "$hook_input" | jq -r '(.tool_exit_code // .exit_code // (try .tool_response.exit_code catch null) // "0") | tostring' 2>/dev/null)
if [ "$exit_code" != "0" ]; then
  hook_log "worktree-track" "$session_id" "allow" "worktree add failed (exit $exit_code) — no tracking"
  echo '{}'
  exit 0
fi

# Extract worktree path from the command arguments.
# Syntax: git worktree add [-f] [--detach] [-b <branch>] [-B <branch>] [--reason <str>] <path> [<commit-ish>]
# The path is the first positional (non-flag) argument.
args_str=$(echo "$command" | sed 's/.*git worktree add //')
read -ra args <<< "$args_str"

worktree_path=""
skip_next=false
for arg in "${args[@]}"; do
  if $skip_next; then
    skip_next=false
    continue
  fi
  case "$arg" in
    -b|-B|--reason) skip_next=true ;;
    -*) ;;
    *) worktree_path="$arg"; break ;;
  esac
done

if [ -z "$worktree_path" ]; then
  echo '{}'
  exit 0
fi

# Resolve to absolute path if relative
if [[ "$worktree_path" != /* ]]; then
  cwd=$(echo "$hook_input" | jq -r '.cwd // ""' 2>/dev/null)
  if [ -n "$cwd" ]; then
    worktree_path="$cwd/$worktree_path"
  fi
fi

# Normalize (resolve ../ segments) — directory exists since the command succeeded
if [ -d "$worktree_path" ]; then
  worktree_path=$(cd "$worktree_path" && pwd)
fi

# Guard: never write empty or whitespace-only paths to the override file
if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
  echo "$worktree_path" > "/tmp/claude-worktree-${session_id}"
  hook_log "worktree-track" "$session_id" "allow" "tracked worktree: $worktree_path"
else
  hook_log "worktree-track" "$session_id" "allow" "no valid worktree path extracted"
fi

echo '{}'
