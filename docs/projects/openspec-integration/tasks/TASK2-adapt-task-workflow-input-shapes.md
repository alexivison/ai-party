# Task 2 - Adapt Task Workflow Input Shapes

**Dependencies:** Task 1 | **Issue:** TBD

---

## Goal

Add the OpenSpec entry adapter to `task-workflow` while keeping the rest of the workflow singular. The only legitimate new branch is where the skill recognizes `change_dir + task_id`, derives the OpenSpec scope packet, and then falls into the existing execution spine. The legacy `task_file` path stays intact rather than being reworked for symmetry's sake.

## Scope Boundary (REQUIRED)

**In scope:**
- Teach `task-workflow` to accept OpenSpec `change_dir + task_id`
- Assemble the OpenSpec scope packet using Task 1's derivation order
- Update completion handling so the workflow checks the selected line in `openspec/.../tasks.md`
- Preserve critic, Codex, sentinel, and pre-PR verification ordering on the OpenSpec path without weakening the existing execution-core rules

**Out of scope (handled by other tasks):**
- Expanding `scribe` requirement sources beyond whatever this task passes through
- Gating apply/archive entrypoints
- Changing evidence policy
- Refactoring or re-validating the legacy `task_file` path beyond not breaking it

**Cross-task consistency check:**
- Task 4 must route OpenSpec execution through this path instead of inventing a second executor
- Task 3 must consume the same shared scope packet this task assembles
- OpenSpec support for `party-dispatch` worker prompts is deferred to a follow-up; this task documents the single-operator invocation shape only

## Reference

Files to study before implementing:

- `claude/skills/task-workflow/SKILL.md:20` - current pre-flight contract
- `claude/skills/task-workflow/SKILL.md:35` - current execution sequence
- `claude/skills/task-workflow/SKILL.md:84` - current checkbox enforcement
- `claude/rules/execution-core.md:9` - canonical workflow sequence
- `claude/rules/execution-core.md:122` - scope enforcement for review prompts

## Design References (REQUIRED for UI/component tasks)

N/A (non-UI task)

## Data Transformation Checklist (REQUIRED for shape changes)

- [ ] Proto definition (N/A)
- [ ] Proto -> Domain converter (N/A)
- [ ] Domain model struct for task-workflow's OpenSpec scope packet
- [ ] Params struct(s) for OpenSpec task input
- [ ] Params conversion functions from OpenSpec input to shared scope packet
- [ ] Any adapters between checkbox updates and the selected OpenSpec task target

## Files to Create/Modify

| File | Action |
|------|--------|
| `claude/skills/task-workflow/SKILL.md` | Modify |
| `claude/rules/execution-core.md` | Modify |
| `claude/hooks/tests/test-openspec-routing.sh` | Modify |

## Requirements

**Functionality:**
- `task-workflow` accepts OpenSpec `change_dir + task_id`
- The OpenSpec scope packet is assembled from proposal capability boundaries/exclusions + design `Non-Goals` + selected task heading context and text
- The workflow still enforces `/write-tests -> implement -> checkboxes -> critics -> codex -> /pre-pr-verification -> PR`
- Scope boundaries for critics, Codex, and sentinel come from the OpenSpec scope packet in the same prompt format the harness already expects
- Checkbox sync updates the selected OpenSpec task entry
- The existing `task_file` path remains untouched rather than being reworked into a new adapter

**Key gotchas:**
- Do not duplicate the full execution sequence in two branches
- OpenSpec completion edits live in Markdown, which the evidence system currently excludes from diff-hash; the workflow should rely on that deliberately, not accidentally
- If proposal/design do not provide enough negative scope to derive `out_of_scope`, fail closed instead of guessing

## Tests

Test cases:
- OpenSpec path: change/task input resolves to a deterministic downstream scope packet
- Missing negative scope source: OpenSpec input fails loudly instead of guessing `out_of_scope`
- Invalid input: incomplete OpenSpec input causes a clear error
- Review-order preservation: the new wording does not weaken the existing execution-core sequence

Verification commands:
- `bash claude/hooks/tests/test-openspec-routing.sh`
- `rg -n "change_dir|task_id|OpenSpec|Non-Goals|out_of_scope|checkbox" claude/skills/task-workflow/SKILL.md claude/rules/execution-core.md`

## Acceptance Criteria

- [ ] `task-workflow` can execute OpenSpec `change_dir + task_id` input without inventing a second downstream workflow
- [ ] OpenSpec scope derivation is deterministic and fails closed when negative scope sources are missing
- [ ] Completion state is updated correctly for the selected OpenSpec task entry
- [ ] The existing `task_file` path remains untouched by this task
