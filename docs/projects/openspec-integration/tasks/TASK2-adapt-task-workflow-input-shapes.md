# Task 2 - Adapt Task Workflow Input Shapes

**Dependencies:** Task 1 | **Issue:** TBD

---

## Goal

Make `task-workflow` accept either accepted input shape while keeping the rest of the workflow singular. The only legitimate branch is at the entry seam where the skill decides whether it was given a `task_file` or a `change_dir + task_id`. Everything after that should read like one workflow, not two stitched together with if-clauses.

## Scope Boundary (REQUIRED)

**In scope:**
- Teach `task-workflow` to accept either `task_file` or `change_dir + task_id`
- Assemble the same scope packet from either input shape
- Update completion handling so the workflow checks either the TASK file or the selected line in `openspec/.../tasks.md`
- Preserve critic, Codex, sentinel, and pre-PR verification ordering regardless of input shape

**Out of scope (handled by other tasks):**
- Expanding `scribe` requirement sources beyond whatever this task passes through
- Gating apply/archive entrypoints
- Changing evidence policy

**Cross-task consistency check:**
- Task 4 must route OpenSpec execution through this path instead of inventing a second executor
- Task 3 must consume the same shared scope packet this task assembles

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
- [ ] Domain model struct for task-workflow's shared scope packet
- [ ] Params struct(s) for classic and OpenSpec task input
- [ ] Params conversion functions from input shape to shared scope packet
- [ ] Any adapters between checkbox updates and the selected task target in each shape

## Files to Create/Modify

| File | Action |
|------|--------|
| `claude/skills/task-workflow/SKILL.md` | Modify |
| `claude/rules/execution-core.md` | Modify |
| `claude/hooks/tests/test-openspec-routing.sh` | Modify |

## Requirements

**Functionality:**
- `task-workflow` accepts either `task_file` or `change_dir + task_id`
- The workflow still enforces `/write-tests -> implement -> checkboxes -> critics -> codex -> /pre-pr-verification -> PR`
- Scope boundaries for critics, Codex, and sentinel come from the shared scope packet, regardless of input shape
- Checkbox sync updates either the TASK file or the selected OpenSpec task entry

**Key gotchas:**
- Do not duplicate the full execution sequence in two branches
- OpenSpec completion edits live in Markdown, which the evidence system currently excludes from diff-hash; the workflow should rely on that deliberately, not accidentally

## Tests

Test cases:
- Classic path: TASK-file input still works
- OpenSpec path: change/task input resolves to the same downstream scope packet
- Invalid input: neither shape or both shapes cause a clear error
- Review-order preservation: the new wording does not weaken the existing execution-core sequence

Verification commands:
- `bash claude/hooks/tests/test-openspec-routing.sh`
- `rg -n "task_file|change_dir|task_id|OpenSpec|checkbox" claude/skills/task-workflow/SKILL.md claude/rules/execution-core.md`

## Acceptance Criteria

- [ ] `task-workflow` can execute either accepted input shape
- [ ] Branching is localized to input capture rather than threaded through the workflow
- [ ] Completion state is updated correctly for both input shapes
