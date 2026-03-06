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

### How Agent Teams work

Agent Teams is a **native Claude Code runtime capability** — the lead session (you) creates teams and the runtime spawns separate Claude Code instances as teammates. This is NOT the Agent tool. The Agent tool creates sub-agents, not teammates. Using the Agent tool here silently creates a duplicate sub-agent alongside the teammate, wasting tokens.

To spawn a teammate: express the intent to create a team in your response text. The runtime handles the rest. Do not use any tool call.

### Steps

1. Run `git diff "$(git merge-base HEAD main)"` and save the output
2. Identify in-scope and out-of-scope files from the TASK
3. Create the team by requesting it in your response (no tool call):

Create an agent team with one teammate in in-process mode: an adversarial code reviewer.

Give the teammate this prompt:
- The diff to review (from step 1)
- In-scope and out-of-scope files (from step 2)
- Focus areas: failure modes, untested edge cases, input validation gaps, race conditions, security surface (injection, privilege escalation, data leakage)
- Output format: max 20 lines, `file:line` references, findings classified as `[must]` (correctness/security) or `[should]` (robustness). If no issues: APPROVE.

## After Spawning

**No code edits until BOTH Codex AND the reviewer return (or 5-minute timeout).** Continue with non-edit work only.

Triage the union of Codex + reviewer findings per `execution-core.md` severity rules. Reviewer findings are advisory — they create no markers and block no gates.
