---
name: planning
description: >
  Feature planning from discovery through task breakdown. Produces design docs
  and implementation plans in `~/.ai-party/research/`, without pushing scratch
  planning docs by default. Use when asked to plan a feature, create a design
  doc, break work into tasks, or produce SPEC.md / DESIGN.md / PLAN.md /
  TASK files.
---

# Planning Skill

Feature planning from discovery through task breakdown. Produces design docs and implementation plans in `~/.ai-party/research/` and keeps them out of git remotes by default.

## Modes

| Mode | Purpose | Output |
|------|---------|--------|
| **Discover** | Explore codebase, clarify requirements, map standards and integration points | Notes (internal) |
| **Design** | Write architecture and data flow | SPEC.md + DESIGN.md |
| **Plan** | Break design into executable tasks | PLAN.md + TASK*.md |

Start wherever the work requires. No hard entry gate — jump straight to Plan if the design is already clear.

## Default Output Location

Write scratch planning artifacts under `~/.ai-party/research/` per `~/.ai-party/research/AGENTS.md`.

- Single-note discoveries or design drafts: `investigations/`, `designs/`, or `plans/` with filename `YYYY-MM-DD-<slug>.md`
- Multi-file planning bundles: `plans/YYYY-MM-DD-<project-slug>/` containing `PLAN.md`, `SPEC.md`, `DESIGN.md`, and `tasks/TASK*.md`

Do not ask the user for a save path unless they explicitly want repo-tracked artifacts.

## Readiness Gate (Before Plan Output)

Before generating PLAN.md or TASK*.md, verify ALL of the following. If any are missing, go back and fill them — materialise into DESIGN.md if needed.

| Requirement | Evidence |
|-------------|----------|
| Existing standards referenced | `file:line` refs, not just file names |
| Data transformation points mapped | Every converter/adapter for each code path |
| Integration points identified | Where new code touches existing code |
| Acceptance criteria defined | Machine-verifiable, not vague |
| UI/component task design context captured | Each UI/component TASK includes a Figma node URL or image/screenshot link/path |

If design decisions were made inline during planning, auto-materialise them into DESIGN.md before final plan output.

## Discover Mode

1. Read any existing specs, PRDs, or issue descriptions
2. Explore codebase to find existing patterns and abstractions
3. Map data transformation points (converters, adapters, params functions)
4. List integration points (handlers, layer boundaries, shared utilities)
5. Identify standards with `file:line` references

## Design Mode

1. Write SPEC.md — requirements and acceptance criteria (skip if external spec provided)
2. Write DESIGN.md — architecture, data flow, transformation points, integration points
3. All patterns must reference existing code with `file:line`
4. Include "Data Transformation Points" section mapping every shape change

## Plan Mode

1. Read DESIGN.md and SPEC.md
2. Create or update the plan bundle at `~/.ai-party/research/plans/<YYYY-MM-DD-<project-slug>>/`
3. Create PLAN.md with task breakdown, dependencies, verification commands
4. Create `tasks/TASK*.md` — small, independently executable tasks (~200 LOC each)
   - For every task that creates or updates UI components, include a `Design References` section with at least one Figma node URL or image/screenshot link/path
5. Evaluate against planning checks (see below)
6. Refine until evaluation passes

## Planning Checks

1. Existing standards referenced with concrete `file:line` paths
2. Data transformation points mapped for schema/field changes
3. Tasks have explicit scope boundaries (in-scope / out-of-scope)
4. Dependencies and verification commands listed per task
5. Requirements reconciled against source inputs; mismatches documented
6. Whole-architecture coherence evaluated across full task sequence
7. UI/component tasks include design references (Figma node URL or image/screenshot link/path)

## Self-Evaluation

Before finalizing PLAN.md, record:

```
## Plan Evaluation Record

PLAN_EVALUATION_VERDICT: PASS | FAIL

Evidence:
- [ ] Existing standards referenced with concrete paths
- [ ] Data transformation points mapped
- [ ] Tasks have explicit scope boundaries
- [ ] Dependencies and verification commands listed per task
- [ ] Requirements reconciled against source inputs
- [ ] Whole-architecture coherence evaluated
- [ ] UI/component tasks include design references
```

If FAIL: fix blocking gaps, re-evaluate.

## Review Checklist

1. Requirements are measurable
2. Existing code patterns referenced with file paths
3. Data transformation points mapped
4. Task boundaries clear with in-scope/out-of-scope
5. Risks and dependencies called out
6. Source conflicts called out explicitly
7. Combined end-state architecture is coherent
8. UI/component tasks include design references (Figma node URL or image/screenshot)

## Output

1. Write the approved planning bundle to `~/.ai-party/research/plans/<YYYY-MM-DD-<project-slug>>/`
2. Stop once the external planning docs are ready
3. Do not create a docs-only PR and do not commit or push scratch planning notes unless the user explicitly asks for repo-tracked artifacts

## Verification Principle

No claims without command output. If you state something about the codebase, show the evidence (file path, line number, command result).

## Templates

- `./templates/spec.md`
- `./templates/design.md`
- `./templates/plan.md`
- `./templates/task.md`
