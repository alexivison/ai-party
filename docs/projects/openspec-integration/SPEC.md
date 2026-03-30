# OpenSpec Integration Into The Claude Code Harness Specification

## Problem Statement

- The harness presently assumes classic planning artifacts. `task-workflow` begins by locating `PLAN.md` and reading scope from a TASK file before any implementation begins (`claude/skills/task-workflow/SKILL.md:20-25`).
- `plan-workflow` likewise assumes it will create `PLAN.md`, `SPEC.md`, `DESIGN.md`, and `TASK*.md`, then hand those files to `task-workflow` (`claude/skills/plan-workflow/SKILL.md:59-74`, `claude/skills/plan-workflow/SKILL.md:196-208`, `claude/skills/plan-workflow/SKILL.md:229-234`).
- `scribe` only accepts `task_file` today and extracts requirements from that file alone (`claude/agents/scribe.md:11-27`), while OpenSpec spreads intent across `proposal.md`, `specs/`, `design.md`, and `tasks.md`.
- A repo-mode detection layer would merely smear conditionals through every skill. The cleaner seam is explicit invocation shape: either the operator provides a TASK file, or the operator provides an OpenSpec change reference.
- The execution and gate layer already lives elsewhere. `execution-core.md`, `evidence.sh`, and `pr-gate.sh` enforce review order, diff-hash freshness, and PR readiness without caring which planning system produced the task (`claude/rules/execution-core.md:9-13`, `claude/rules/execution-core.md:44-48`, `claude/hooks/lib/evidence.sh:99-123`, `claude/hooks/pr-gate.sh:30-89`).

## Goal

The harness shall execute feature work from either accepted planning input shape, with OpenSpec as the planning truth for the next project and with the same evidence, critic, Codex, and PR-gate protections the harness already trusts.

## User Experience

| Scenario | User Action | Expected Result |
|----------|-------------|-----------------|
| OpenSpec planning handoff | Create `openspec/changes/<slug>/` via `/opsx:propose`, then invoke the harness with `change_dir=<slug>` and `task_id=1.2` | The harness reads `proposal.md`, `design.md`, `specs/`, and the selected checkbox in `tasks.md`, then runs the normal execution-core flow without requiring classic `PLAN.md` or `TASK*.md` runtime artifacts |
| OpenSpec requirements audit | Execute an OpenSpec task that has proposal, design, and delta specs | `scribe` audits the diff against the OpenSpec artifact bundle and returns the usual coverage matrix and verdict |
| Classic task execution | Invoke the harness with a `TASK*.md` path | The same downstream execution-core flow runs; the distinction is only the entry input shape |
| Stock apply bypass attempt | Try to use stock `/opsx:apply` for code execution | The harness denies or redirects the attempt so execution still flows through `task-workflow` and the existing gates |
| Premature archive attempt | Try to archive an OpenSpec change before execution proof exists | The archive wrapper/gate refuses and reports the missing completion evidence |

## Acceptance Criteria

- [ ] Track 1 allows feature execution from stock OpenSpec artifacts alone: `proposal.md`, `specs/`, `design.md`, and `tasks.md`
- [ ] `task-workflow` accepts either `task_file` or `change_dir + task_id`, with branching limited to input capture rather than threaded through the execution sequence
- [ ] `scribe` accepts either a TASK file or an OpenSpec requirement bundle and preserves its current verdict and coverage output shape
- [ ] OpenSpec execution paths cannot bypass `execution-core.md`, critic review, Codex review, evidence recording, or `pr-gate.sh`
- [ ] `/opsx:archive` is gated behind the same completion proof the harness already trusts for code changes
- [ ] No repo-mode detection layer or `mode` field is required for task execution or requirement auditing
- [ ] The evidence policy for `openspec/**/*.md` changes is explicit and regression-tested

## Non-Goals

- Rewriting OpenSpec's proposal, spec-delta, design, or task formats.
- Replacing the harness review loop with stock `/opsx:apply` or `/opsx:verify`.
- Adding repo-mode detection and threaded `if classic / if OpenSpec` branching across the workflow docs.
- Inventing a shell parser for OpenSpec Markdown when the skills can read the artifacts directly.

## Technical Reference

Implementation details, task breakdown, and compatibility decisions live in [DESIGN.md](./DESIGN.md).
