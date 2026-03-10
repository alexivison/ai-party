#!/usr/bin/env bash

# Claude Code Bash guard hook
# 1. Blocks branch switching/creation in main worktree
# 2. Blocks Bash-based file editing (sed -i, awk > file, etc.) — use Edit/Write tools
#
# Triggered: PreToolUse on Bash tool
# Outputs JSON on all paths (required by hook runner when sharing a hook group)

INPUT=$(cat)
if ! COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null); then
    echo '{}'
    exit 0
fi

if [ -z "$COMMAND" ]; then
    echo '{}'
    exit 0
fi

# ── Guard: Block Bash file-writing on implementation files ──
# Marker invalidation only fires on Edit|Write tools. Bash edits bypass it.
# Only block explicit in-place mutation commands (sed -i, awk inplace).
# Redirect operators (>, >>) are too common in read-only shell (>/dev/null, etc.) to block broadly.
if echo "$COMMAND" | grep -qE 'sed\s+-i|awk\s.*-i\s*inplace'; then
    cat << 'GUARD_EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Use Edit/Write tools instead of Bash for file modifications. Marker invalidation depends on Edit/Write tool hooks."
  }
}
GUARD_EOF
    exit 0
fi

# ── Guard: Block branch switching in main worktree ──

# Check for branch switching/creation commands
if ! echo "$COMMAND" | grep -qE 'git\s+(checkout|switch)'; then
    echo '{}'
    exit 0
fi

# Allow file checkouts (git checkout -- file, git checkout HEAD -- file, etc.)
if echo "$COMMAND" | grep -qE 'git\s+checkout\s+(--\s|HEAD\s)'; then
    echo '{}'
    exit 0
fi

# Allow switching to main/master
if echo "$COMMAND" | grep -qE 'git\s+(checkout|switch)\s+(main|master)\s*$'; then
    echo '{}'
    exit 0
fi

# Get working directory
WORKING_DIR=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$WORKING_DIR" ] && WORKING_DIR=$(pwd)

cd "$WORKING_DIR" 2>/dev/null || { echo '{}'; exit 0; }

# Not in a git repo - allow (nothing to protect)
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo '{}'
    exit 0
fi

# Allow if already in a worktree (not the main worktree)
MAIN_WORKTREE=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
GIT_ROOT=$(git rev-parse --show-toplevel)

if [ "$GIT_ROOT" != "$MAIN_WORKTREE" ]; then
    echo '{}'
    exit 0
fi

# Rewrite: branch switch → worktree add
REPO_NAME=$(basename "$GIT_ROOT" 2>/dev/null || echo "repo")

# Extract target branch from: git checkout [-b] <branch> | git switch [-c] <branch>
# Strip flags first, then take the last token as the branch name.
BRANCH=$(echo "$COMMAND" | sed -E 's/git\s+(checkout|switch)\s+//' | sed -E 's/-(b|c|B|C)\s+//' | awk '{print $NF}')

if [ -z "$BRANCH" ]; then
  # Can't determine branch — fall back to deny
  cat << 'GUARD_EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Could not parse branch name from checkout/switch command in main worktree."
  }
}
GUARD_EOF
  exit 0
fi

WORKTREE_PATH="../${REPO_NAME}-${BRANCH}"

# Determine if this is a new branch (-b/-c flag) or existing
if echo "$COMMAND" | grep -qE '\s-(b|c|B|C)\s'; then
  REWRITTEN="git worktree add ${WORKTREE_PATH} -b ${BRANCH} && cd ${WORKTREE_PATH}"
else
  REWRITTEN="git worktree add ${WORKTREE_PATH} ${BRANCH} && cd ${WORKTREE_PATH}"
fi

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Rewrote branch switch to worktree: ${BRANCH} → ${WORKTREE_PATH}",
    "updatedInput": {
      "command": "${REWRITTEN}"
    }
  }
}
EOF
exit 0
