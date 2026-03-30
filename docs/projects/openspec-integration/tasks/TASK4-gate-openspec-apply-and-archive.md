# Task 4 - Gate OpenSpec Apply And Archive

**Dependencies:** Task 2, Task 3 | **Issue:** TBD

---

## Goal

Ensure OpenSpec archival cannot sidestep the harness, and document the blessed execution path honestly. If planning moves but the gates do not, the whole exercise turns into an attractive bypass mechanism. If the hooks cannot block a stock slash command, the docs must say so plainly instead of promising wizardry.

## Scope Boundary (REQUIRED)

**In scope:**
- Add a harness-safe archive gate that denies archival when required completion evidence is missing or when the associated PR is not merged
- Introduce the blessed OpenSpec execution/archive entrypoints or wrapper guidance the team is expected to use
- Document that stock `/opsx:apply` is unsupported for harnessed execution because it bypasses `execution-core.md`, and state the residual bypass risk honestly
- Reuse the existing evidence readers and PR-gate semantics, but add a terminal completion signal rather than reusing PR readiness as archive readiness

**Out of scope (handled by other tasks):**
- Repo-mode detection or workflow auto-routing
- Optional metadata or evidence-policy refinement
- Rewriting PR-gate semantics

**Cross-task consistency check:**
- Archive gating must rely on the same evidence spine that already governs PR creation, plus merged-PR state
- Any apply wrapper or guidance must route real execution back through Task 2's unified `task-workflow` path
- The guidance must speak in accepted input shapes, not in repo modes

## Reference

Files to study before implementing:

- `claude/hooks/pr-gate.sh:30` - current PR-create interception logic
- `claude/hooks/pr-gate.sh:55` - required evidence selection
- `claude/hooks/lib/evidence.sh:185` - evidence append/check helpers
- `claude/settings.json:84` - current Bash PreToolUse hook order
- `claude/settings.json:155` - Skill hook surface available for wrapper-style enforcement
- `gh pr view --help` - merged PR state lookup contract for archive gating

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
| `claude/settings.json` | Modify |
| `claude/skills/task-workflow/SKILL.md` | Modify |

## Requirements

**Functionality:**
- Archive attempts are denied unless the required evidence spine is satisfied and the associated PR is merged
- The deny path reports concrete missing markers or missing merged-PR proof instead of vague "not ready" prose
- The harness documents or exposes one blessed execution path for OpenSpec work, and that path routes through `task-workflow` using explicit `change_dir + task_id` input
- Stock `/opsx:apply` is explicitly marked unsupported for harnessed execution, and the residual bypass risk is documented because current hooks cannot hard-block arbitrary third-party slash commands

**Key gotchas:**
- Current hook surfaces cannot intercept arbitrary third-party slash commands directly; do not promise magic that the hook system cannot perform
- Do not fork PR-gate logic unnecessarily when the existing evidence helpers can be shared
- Do not treat PR readiness as archive readiness; merged-PR proof is a separate state and should be checked via `gh`

## Tests

Test cases:
- Archive denied when required evidence is missing
- Archive denied when the evidence is fresh but the associated PR is not merged
- Archive allowed when required evidence is present for the current diff-hash and the associated PR is merged
- PR gate behavior remains unchanged for normal PR creation
- Wrapper/guidance text clearly routes OpenSpec execution back through the unified input-shape design

Verification commands:
- `bash claude/hooks/tests/test-archive-gate.sh`
- `bash claude/hooks/tests/test-pr-gate.sh`
- `gh pr view --json state,mergedAt`
- `rg -n "opsx:apply|archive|merged|change_dir|task_id|OpenSpec" claude/skills/task-workflow/SKILL.md claude/hooks/archive-gate.sh`

## Acceptance Criteria

- [ ] OpenSpec archive is gated by fresh evidence plus merged-PR completion proof
- [ ] The harness has a clear, blessed execution path for OpenSpec work that does not rely on stock `/opsx:apply`
- [ ] The docs state the residual unsupported-path risk honestly instead of promising impossible hard-blocking
- [ ] PR-gate semantics remain intact after archive-gate wiring lands
