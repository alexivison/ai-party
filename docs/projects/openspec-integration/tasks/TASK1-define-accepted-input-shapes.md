# Task 1 - Define Accepted Input Shapes

**Dependencies:** none | **Issue:** TBD

---

## Goal

Define the accepted planning input shapes before any workflow logic changes. The contract should be plain: the operator provides either a `task_file`, or an OpenSpec `change_dir + task_id`. From there the downstream execution path is singular. No `mode` flag, no repo detection layer, no Bash parser library pretending to be clever.

## Scope Boundary (REQUIRED)

**In scope:**
- Document the two accepted task-execution input shapes
- Define the shared downstream work packet those shapes must produce
- Update planning guidance so OpenSpec feature work hands off explicitly as `change_dir + task_id`
- State the invariants that all later tasks must preserve: one execution path, one review spine, one evidence spine

**Out of scope (handled by other tasks):**
- Implementing the task-workflow entry changes
- Extending `scribe` to use polymorphic requirement sources
- Gating apply/archive flows
- Changing evidence policy

**Cross-task consistency check:**
- Tasks 2 and 3 must consume these documented input shapes rather than inventing new discriminants
- The contract must not introduce `detect_planning_mode()` or a `mode` field
- The contract must not require a shell parser for `tasks.md`

## Reference

Files to study before implementing:

- `claude/skills/task-workflow/SKILL.md:20` - current PLAN/TASK pre-flight assumptions
- `claude/skills/plan-workflow/SKILL.md:59` - current classic artifact contract
- `claude/skills/plan-workflow/SKILL.md:196` - current finalize/handoff assumption
- `claude/rules/execution-core.md:9` - existing single downstream execution sequence

## Design References (REQUIRED for UI/component tasks)

N/A (non-UI task)

## Data Transformation Checklist (REQUIRED for shape changes)

- [ ] Proto definition (N/A)
- [ ] Proto -> Domain converter (N/A)
- [ ] Domain model struct for the shared downstream work packet
- [ ] Params struct(s) for `task_file` and for `change_dir + task_id`
- [ ] Params conversion functions from accepted input shape to shared work packet
- [ ] Any adapters between OpenSpec task numbering and the shared checkbox-target concept

## Files to Create/Modify

| File | Action |
|------|--------|
| `claude/skills/task-workflow/SKILL.md` | Modify |
| `claude/skills/plan-workflow/SKILL.md` | Modify |
| `claude/rules/execution-core.md` | Modify |
| `claude/hooks/tests/test-openspec-routing.sh` | Create |

## Requirements

**Functionality:**
- Document exactly two accepted input shapes for task execution
- Define the shared downstream work packet those inputs must produce
- Make OpenSpec handoff explicit in docs without introducing repo detection
- Preserve the existing execution-core sequence as the sole downstream path

**Key gotchas:**
- Do not smuggle repo-mode detection back in under another name
- Do not replace a clear prompt contract with a Bash helper that merely re-parses Markdown

## Tests

Test cases:
- Docs state the two accepted input shapes clearly
- Docs do not mention `detect_planning_mode()` or a `mode` field
- OpenSpec handoff is explicit in `plan-workflow`
- Execution-core still describes one downstream sequence

Verification commands:
- `bash claude/hooks/tests/test-openspec-routing.sh`
- `rg -n "task_file|change_dir|task_id|detect_planning_mode|mode" claude/skills/task-workflow/SKILL.md claude/skills/plan-workflow/SKILL.md claude/rules/execution-core.md`

## Acceptance Criteria

- [ ] The harness documents two accepted input shapes and one downstream execution path
- [ ] No repo-mode detection layer or `mode` field is introduced
- [ ] OpenSpec handoff is explicit without creating classic runtime artifacts for OpenSpec projects
