#!/bin/bash
# PreToolUse hook: non-blocking reminder to run full checks before pushing.

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[[ "$command" != *"git push"* ]] && exit 0

cat <<'EOF'
{
  "hookSpecificOutput": {
    "additionalContext": "STOP. Before pushing you MUST have run the FULL check suite (typecheck + lint + tests) via check-runner and test-runner sub-agents. Not partially, not just lint — the full suite. If you have not, abort this push and run them now."
  }
}
EOF
exit 0
