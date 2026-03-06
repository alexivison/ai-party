---
name: review-team
description: >-
  Spawn an adversarial reviewer teammate via Agent Teams to stress-test code changes.
  Runs concurrently with Codex review after critics approve. Focuses on failure modes,
  edge cases, input validation gaps, race conditions, and security surface. Advisory
  only — produces no gating markers. Requires CLAUDE_TEAM_REVIEW=1 environment variable.
user-invocable: false
---

# Review Team — Adversarial Reviewer

Spawn an Agent Teams teammate that tries to break the code while Codex reviews it. Both run concurrently; advisory only — no gating markers.

## Preflight

Skip silently (proceed Codex-only) if `CLAUDE_TEAM_REVIEW` is not `1`.

## Spawn

Use the **Agent tool** with `subagent_type: "teammate"`. This is an Agent Teams teammate — not a regular sub-agent. Regular `code-critic(...)` sub-agents are the wrong mechanism.

```
Agent(
  subagent_type: "teammate",
  name: "adversarial-reviewer",
  prompt: <see below>
)
```

### Prompt Template

```
You are an adversarial code reviewer. Your job is to try to break this code.

## Diff
<paste output of: git diff "$(git merge-base HEAD main)">

## Scope
In-scope: <files from TASK>
Out-of-scope: <everything else>

## Focus
- Failure modes and error paths
- Edge cases the tests don't cover
- Input validation gaps
- Race conditions and state corruption
- Security surface (injection, privilege escalation, data leakage)

## Output format
- Max 20 lines, with `file:line` references
- Classify each finding: `[must]` (correctness/security) or `[should]` (robustness)
- If no issues: return **APPROVE**
```

## After Spawning

**No code edits until BOTH Codex AND the reviewer return (or 5-minute timeout).** Continue with non-edit work only.

Triage the union of Codex + reviewer findings per `execution-core.md` severity rules. Reviewer findings are advisory — they create no markers and block no gates.
