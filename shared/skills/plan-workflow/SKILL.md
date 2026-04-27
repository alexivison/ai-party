---
name: plan-workflow
description: >-
  Orchestrate plan creation by dispatching the companion to do deep research
  and write dated planning docs under `~/.ai-party/docs/research/`. Use when
  the user wants to plan a feature, investigate a ticket, design an approach,
  create a plan, scope work, or break work into executable tasks. The primary
  agent orchestrates; the companion writes the plan artifacts.
user-invocable: true
---

# Plan Workflow

Orchestrate the companion to produce dated planning docs in `~/.ai-party/docs/research/`. You are the primary agent. Your role is context-gathering, dispatch, verification, relay, and finalization. The companion does the deep reasoning and writes the docs.

Path convention used below:

- `<primary-agent-skill-root>` = the primary agent's own skill root
- `<companion-agent-skill-root>` = the companion agent's own skill root
- `<agent-skill-root>` = the current agent's own skill root

Canonical templates for this workflow live beside this skill:

- `./templates/create-plan.md`
- `./templates/revise-plan.md`
- `./templates/spec.md`
- `./templates/design.md`
- `./templates/plan.md`
- `./templates/task.md`

`./templates/spec.md` is available for cases where the user explicitly wants a separate repo-tracked specification artifact. Canonical dated docs under `~/.ai-party/docs/research/` remain design / plan / task docs.

## Outputs

Write planning docs directly under `~/.ai-party/docs/research/` without asking the user for a path:

- Plan: `YYYY-MM-DD-plan-<slug>.md` with frontmatter `type: plan`
- Design: `YYYY-MM-DD-design-<slug>.md` with frontmatter `type: design`
- Separate task docs: `YYYY-MM-DD-task-<slug>.md` or `...-<n>.md` with frontmatter `type: plan`

Default to a single-file plan. Only create separate task docs when one file would become unclear. Only create repo-tracked planning artifacts when the user explicitly asks for them.

## Phase 1 — Gather Context

Before dispatching the companion, assemble the context needed for good reasoning.

1. **Understand the ask** — Extract the goal, constraints, and expected outputs.
2. **Fetch external context** — Pull in Linear, Notion, or other referenced material first.
3. **Read relevant code** — Identify the modules, entry points, and existing patterns the work will touch.
4. **Check for existing plans** — Look under `~/.ai-party/docs/research/` first, then repo-tracked plan docs only when the user explicitly wants tracked docs.
5. **Identify scope boundaries** — Capture in-scope / out-of-scope boundaries and known dependencies.
6. **Map planning evidence** — Gather the evidence the companion needs for a strong plan:
   - Existing standards with `file:line` references
   - Data transformation points for each code path
   - Integration points where new code touches existing code
   - Acceptance criteria that are concrete and testable
   - Design references for UI/component work (Figma node URL or image/screenshot link/path)

If requirements are unclear, clarify them before dispatching. Do not write the plan yourself.

## Phase 2 — Dispatch to the Companion

Compose a rich prompt and send it through the shared transport skill. Use `./templates/create-plan.md` for initial creation and `./templates/revise-plan.md` for revisions.

Write the filled prompt to a temp file, then dispatch:

```bash
PROMPT_FILE=$(mktemp /tmp/companion-plan-prompt-XXXXXX.md)
# Copy template, fill in placeholders, then dispatch.

<primary-agent-skill-root>/agent-transport/scripts/tmux-companion.sh \
  --prompt "$(cat "$PROMPT_FILE")" <work_dir>
```

### Error Handling

Check stdout for the transport sentinel strings:

- `COMPANION_TASK_REQUESTED` — success, proceed
- `COMPANION_TASK_DROPPED` — the companion pane is busy; retry or inform the user
- `COMPANION_NOT_AVAILABLE` — the session has no companion; inform the user that this workflow requires companion access

### Choosing the Right Mode

| Situation | Mode | Why |
|-----------|------|-----|
| New plan from scratch | `--prompt "<task>" <work_dir>` | The companion researches and writes the planning docs |
| Review an existing plan | `--plan-review "<plan_path>" <work_dir>` | Returns TOON findings against the plan |
| Iterate on a draft | `--prompt "<feedback>" <work_dir>` | Applies revisions to the existing doc set |

`--plan-review` is for evaluating a plan file that already exists. For initial creation or revision, use `--prompt`.

Dispatch is non-blocking. Verify file paths and prepare follow-up checks while the companion works. Do not poll.

## Phase 3 — Receive and Verify

When `[COMPANION] Task complete. Response at: <path>` arrives:

1. **Read the response file first** — It is the authoritative result channel. Check `STATUS:`. If failed, report it.
2. **Extract artifact paths** — Read `DESIGN:`, `PLAN:`, `TASKS:`, and `SPEC:` if present.
3. **Open the planning docs** — Read the returned files, not assumed paths.
4. **Verify against the codebase** — Confirm referenced files, functions, and APIs exist.
5. **Run the readiness gate** — Do not accept the output unless all of the following are satisfied:

| Requirement | Evidence |
|-------------|----------|
| Existing standards referenced | Concrete `file:line` refs, not just file names |
| Data transformation points mapped | Every converter/adapter for each relevant code path |
| Integration points identified | Explicit touch points between new and existing code |
| Acceptance criteria defined | Machine-verifiable, not vague |
| UI/component design context captured | Each UI/component task includes a Figma node URL or image/screenshot link/path |

If the companion made design decisions inline, ensure those decisions are materialized into a design doc before final plan acceptance.

### Planning Checks

Evaluate the plan artifacts against all of these checks:

1. Existing standards are referenced with concrete `file:line` paths
2. Data transformation points are mapped for every schema or field change
3. Tasks have explicit scope boundaries (`In scope` / `Out of scope`)
4. Dependencies and verification commands are listed per task
5. Requirements are reconciled against source inputs and mismatches are documented
6. Whole-architecture coherence is evaluated across the full task sequence
7. UI/component tasks include design references

### Self-Evaluation

Confirm the plan doc includes the `## Plan Evaluation Record` block from `./templates/plan.md` and that the verdict is `PASS` only when the evidence supports it. If the verdict should be `FAIL`, iterate before presenting.

## Phase 4 — Present to the User

Present the plan with verification notes:

1. Summarize the main outputs (design/plan/tasks, plus any explicit repo-tracked spec if present)
2. Highlight any concerns or unresolved tradeoffs
3. Ask for approval or revision feedback

Keep the presentation concise. The plan docs carry the detail; your job is to surface what matters for a decision.

## Phase 5 — Iterate

If the user has feedback, fill `./templates/revise-plan.md` and dispatch it with `--prompt`. Include both the user's feedback and any blocking concerns you found during verification.

Repeat Phase 3–5 until the plan is acceptable. Preserve unchanged sections; only revise what the feedback or readiness checks require.

## Phase 6 — Finalize

Once the user approves:

1. **Confirm artifact locations** — Ensure the plan doc is at `~/.ai-party/docs/research/YYYY-MM-DD-plan-<slug>.md`. Keep related design/task docs as flat siblings in the same directory. If the user explicitly requested a separate repo-tracked spec, verify that location separately.
2. **Dispatch plan review (mandatory)** — Every created plan must go through companion plan review:

```bash
<primary-agent-skill-root>/agent-transport/scripts/tmux-companion.sh \
  --plan-review "<plan_path>" <work_dir>
```

When `[COMPANION] Plan review complete. Findings at: <path>` arrives, triage findings per `tmux-handler` (blocking / non-blocking / out-of-scope). Present blocking concerns to the user and iterate if needed.

3. **Signal readiness** — Tell the user the plan is ready for execution. If appropriate, suggest `/task-workflow`.

## Quick Reference

| Phase | Primary Agent's Job | Companion's Job |
|-------|---------------------|-----------------|
| Gather | Read code, fetch tickets, assemble constraints and evidence | — |
| Dispatch | Fill prompt template, send via transport | Research and write planning docs |
| Verify | Check paths, code references, readiness gate, planning checks | — |
| Present | Summarize outputs, flag concerns | — |
| Iterate | Relay feedback and verification gaps | Revise docs |
| Finalize | Confirm locations, run mandatory plan review | Formal plan review |

## Anti-Patterns

- **Writing the plan yourself** — This workflow exists to utilize the companion system.
- **Thin prompts** — Poor prompts produce shallow plans.
- **Generic references** — File names without `file:line` evidence are insufficient.
- **Silent corrections** — Surface concerns to the user; do not quietly rewrite the companion's output.
- **Skipping the readiness gate** — Missing standards, transformation maps, or acceptance criteria produce weak plans.
- **Polling the companion** — Wait for the tmux completion notice instead.

## Integration with Other Workflows

- `task-workflow` can execute work directly from these dated research plan docs.
- `party-dispatch` can parallelize approved tasks across worker sessions.
- `bugfix-workflow` may invoke this skill when investigation shows the fix needs planning.
