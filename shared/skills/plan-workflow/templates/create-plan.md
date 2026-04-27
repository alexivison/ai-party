## Task
Create dated planning docs for: <goal description>

## Context
<paste or summarize: ticket details, relevant code excerpts, existing architecture, constraints, user preferences>

## Requirements
- Use the canonical templates from this `plan-workflow` skill. Paths below are relative to the skill directory:
  - `./templates/spec.md`
  - `./templates/design.md`
  - `./templates/plan.md`
  - `./templates/task.md`
- Default to a single-file plan. Only create separate task docs when one file would become unclear.
- Create a design doc whenever design decisions need to be materialized to satisfy the readiness gate.
- Create a spec doc only when the user explicitly asked for a separate repo-tracked specification artifact. Otherwise, capture requirements in the design or plan doc.
- Write planning docs to `~/.ai-party/docs/research/` using dated filenames:
  - Plan: `YYYY-MM-DD-plan-<project-slug>.md`
  - Design: `YYYY-MM-DD-design-<project-slug>.md`
  - Task docs: `YYYY-MM-DD-task-<project-slug>-<n>.md`
- Add required frontmatter to each created doc:
  - `title`
  - `date`
  - `agent: <companion-agent-name>`
  - `type`
  - `related`
  - `status: draft`
- For dated docs under `~/.ai-party/docs/research/`, keep `type` aligned with the docs workspace contract (`plan` or `design` here; task docs also use `plan`).
- Keep task doc links flat as sibling files, never a `tasks/` subdirectory.
- Apply the readiness gate before finalizing:
  - Existing standards include concrete `file:line` references
  - Data transformation points are mapped for every relevant code path
  - Integration points are identified
  - Acceptance criteria are concrete and testable
  - UI/component tasks include design references (Figma node URL or image/screenshot link/path)
- Apply the planning checks:
  - Tasks have explicit scope boundaries
  - Dependencies and verification commands are listed per task
  - Requirements are reconciled against source inputs
  - Whole-architecture coherence is evaluated across the task sequence
- Include the `## Plan Evaluation Record` block from `./templates/plan.md` and set `PLAN_EVALUATION_VERDICT` honestly.
- Keep it concise. A plan is a map, not a novel.

## Output
Write plan to: `~/.ai-party/docs/research/YYYY-MM-DD-plan-<project-slug>.md`
Write any design/task docs to the same directory as flat sibling files.
If the user explicitly asked for a repo-tracked spec, write it to the requested tracked location using `./templates/spec.md`.

## Response File Contract
After writing all files, write summary to response file (<response_path>):
- `STATUS: SUCCESS` or `STATUS: FAILED` with reason
- `PLAN: <actual plan path>`
- `DESIGN: <actual design path>` if created
- `SPEC: <actual spec path>` if created
- `TASKS:` followed by one path per line (omit if none)
- Any warnings or assumptions made
