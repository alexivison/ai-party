# Task 4 - Gate OpenSpec Apply And Archive

**Dependencies:** Task 2, Task 3 | **Issue:** TBD

---

## Goal

Ensure OpenSpec execution and archival cannot sidestep the harness. If planning moves but the gates do not, the whole exercise turns into an attractive bypass mechanism.

## Scope Boundary (REQUIRED)

**In scope:**
- Add a harness-safe archive gate that denies archival when required completion evidence is missing
- Introduce the blessed OpenSpec execution/archive entrypoints or wrapper guidance the team is expected to use
- Document that stock `/opsx:apply` is unsupported for harnessed execution because it bypasses `execution-core.md`
- Reuse the existing evidence readers and PR-gate semantics rather than creating a second completion checklist

**Out of scope (handled by other tasks):**
- Repo-mode detection or workflow auto-routing
- Optional metadata or evidence-policy refinement
- Rewriting PR-gate semantics

**Cross-task consistency check:**
- Archive gating must rely on the same evidence spine that already governs PR creation
- Any apply wrapper or guidance must route real execution back through Task 2's unified `task-workflow` path
- The guidance must speak in accepted input shapes, not in repo modes

## Reference

Files to study before implementing:

- `claude/hooks/pr-gate.sh:30` - current PR-create interception logic
- `claude/hooks/pr-gate.sh:55` - required evidence selection
- `claude/hooks/lib/evidence.sh:185` - evidence append/check helpers
- `claude/settings.json:84` - current Bash PreToolUse hook order
- `claude/settings.json:155` - Skill hook surface available for wrapper-style enforcement

## Design References (REQUIRED for UI/component tasks)

N/A (non-UI task)

## Data Transformation Checklist (REQUIRED for shape changes)

- [ ] Proto definition (N/A)
- [ ] Proto -> Domain converter (N/A)
- [ ] Domain model struct for archive-gate decision inputs
- [ ] Params struct(s) for archive attempts and OpenSpec wrapper arguments
- [ ] Params conversion functions from hook input to required-evidence checks
- [ ] Any adapters between OpenSpec change identifiers and the harness session/evidence model

## Files to Create/Modify

| File | Action |
|------|--------|
| `claude/hooks/archive-gate.sh` | Create |
| `claude/hooks/tests/test-archive-gate.sh` | Create |
| `claude/hooks/pr-gate.sh` | Modify |
| `claude/settings.json` | Modify |
| `claude/skills/task-workflow/SKILL.md` | Modify |
| `claude/skills/plan-workflow/SKILL.md` | Modify |

## Requirements

**Functionality:**
- Archive attempts are denied when the same evidence spine required for PR readiness is not satisfied
- The deny path reports concrete missing markers instead of vague "not ready" prose
- The harness documents or exposes one blessed execution path for OpenSpec work, and that path routes through `task-workflow` using explicit `change_dir + task_id` input
- Stock `/opsx:apply` is explicitly marked unsupported for harnessed execution

**Key gotchas:**
- Current hook surfaces cannot intercept arbitrary third-party slash commands directly; do not promise magic that the hook system cannot perform
- Do not fork PR-gate logic unnecessarily when the existing evidence helpers can be shared

## Tests

Test cases:
- Archive denied when required evidence is missing
- Archive allowed when required evidence is present for the current diff-hash
- PR gate behavior remains unchanged for normal PR creation
- Wrapper/guidance text clearly routes OpenSpec execution back through the unified input-shape design

Verification commands:
- `bash claude/hooks/tests/test-archive-gate.sh`
- `bash claude/hooks/tests/test-pr-gate.sh`
- `rg -n "opsx:apply|archive|change_dir|task_id|OpenSpec" claude/skills/task-workflow/SKILL.md claude/skills/plan-workflow/SKILL.md`

## Acceptance Criteria

- [ ] OpenSpec archive is gated by the existing evidence spine
- [ ] The harness has a clear, blessed execution path for OpenSpec work that does not rely on stock `/opsx:apply`
- [ ] PR-gate semantics remain intact after archive-gate wiring lands
