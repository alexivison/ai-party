## Plan Revision Request

The user reviewed the plan set anchored at <plan_path> and has feedback:

<user's feedback, verbatim or faithfully paraphrased>

## Instructions
- Read the current plan at <plan_path> and any related dated sibling docs (`design`, `spec`, `task`) in the same directory
- Treat a `spec` doc as optional and only preserve or update it when the user explicitly asked for a separate repo-tracked spec
- Apply the requested changes to the plan and any affected related docs
- If feedback changes task boundaries, ordering, or scope: regenerate the affected task docs
- Follow the canonical templates from this `plan-workflow` skill:
  - `./templates/spec.md`
  - `./templates/design.md`
  - `./templates/plan.md`
  - `./templates/task.md`
- Preserve parts the user did not comment on unless they fail the readiness gate or planning checks
- Keep flat-file links and related docs in sync
- Re-run the readiness gate and planning checks before finishing
- Keep the `## Plan Evaluation Record` block current

## Response File Contract
Write to response file:
- `STATUS: SUCCESS` or `STATUS: FAILED` with reason
- `PLAN: <plan path>`
- `DESIGN: <design path>` if present
- `SPEC: <spec path>` if present because the user explicitly requested a separate repo-tracked spec
- `TASKS:` list of all related task doc paths (created, updated, unchanged)
- `CHANGED:` list of files modified in this revision
