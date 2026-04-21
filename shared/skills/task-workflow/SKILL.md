---
name: task-workflow
description: >-
  Execute planned work with full autonomous workflow including tests,
  implementation, critic review, companion review, and PR creation. Works with
  any planning source that provides scope, requirements, and a goal — TASK
  files, external planning tools, or direct user instructions. Covers the
  entire cycle from worktree creation to draft PR.
user-invocable: true
---

# Task Workflow

Execute planned work using the full autonomous pipeline defined in the shared execution-core rules at `shared/execution-core.md` (also accessible via agent-local shims such as `claude/rules/execution-core.md`).

Invoking this skill opts the session into the `task` execution-preset — the PR gate will then require the full task-preset evidence set (critics, requirements-auditor, companion review, pre-pr-verification). See `shared/execution-core.md` for the preset-to-evidence mapping.

## When to Use

Use task-workflow for **planned work** from any source that provides scope, requirements, and a goal:
- TASK*.md files from a project plan
- External planning tool artifacts (Linear, Notion, etc.)
- Direct user instructions with clear scope

For bug fixes → use `bugfix-workflow`. For non-behavioral small changes → use `quick-fix-workflow`.

## What This Skill Adds

Task-workflow is a thin shim over execution-core. It triggers the full pipeline and ensures:

1. **Scope extraction** — Read the planning source and extract scope boundaries, requirements, and goal per the pre-implementation gate in `shared/execution-core.md`.
2. **Requirements audit** — Because planned work has requirements, the requirements-auditor runs alongside critics.
3. **Source-file updates** — Tracking files (TASK/PLAN/external checkboxes) are updated alongside the implementation commit.

## Execution

Follow `shared/execution-core.md` end-to-end — pre-implementation gate, RED evidence, implementation, source-file updates, critics (with requirements-auditor), companion review, commit, pre-pr-verification, PR. No stopping until PR is created.

Concrete stage mechanisms come from your agent's "Stage Bindings" section (`claude/CLAUDE.md` or `codex/AGENTS.md`). This recipe describes the stages; the bindings describe how to execute them.
