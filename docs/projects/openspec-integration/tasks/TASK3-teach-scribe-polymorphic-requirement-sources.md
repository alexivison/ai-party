# Task 3 - Teach Scribe Polymorphic Requirement Sources

**Dependencies:** Task 1 | **Issue:** TBD

---

## Goal

Preserve requirement auditing when the planning truth may come from different artifacts. `scribe` should accept one `requirement_sources` contract backed either by a TASK file or by an OpenSpec bundle. The extraction phase may adapt; the audit logic and output shape should not.

## Scope Boundary (REQUIRED)

**In scope:**
- Replace the TASK-file-only assumption with one `requirement_sources` contract
- Support `requirement_sources` backed by either a TASK file or `proposal.md + specs/ + design.md + selected task`
- Preserve current severity labels, verdict rules, and coverage-matrix output shape
- Update the caller contract so `task-workflow` passes the correct requirement sources and changed test files

**Out of scope (handled by other tasks):**
- Reworking code-critic or minimizer semantics
- Gating apply/archive entrypoints
- Changing evidence policy

**Cross-task consistency check:**
- Task 2 must pass the shared scope packet rather than raw unvalidated OpenSpec text
- Task 4 must rely on the same OpenSpec artifact bundle this task expects when routing execution/archive guidance

## Reference

Files to study before implementing:

- `claude/agents/scribe.md:13` - current prompt inputs
- `claude/agents/scribe.md:21` - current requirement extraction rules
- `claude/agents/scribe.md:31` - current implementation mapping rules
- `claude/skills/task-workflow/SKILL.md:45` - current scribe invocation expectations

## Design References (REQUIRED for UI/component tasks)

N/A (non-UI task)

## Data Transformation Checklist (REQUIRED for shape changes)

- [ ] Proto definition (N/A)
- [ ] Proto -> Domain converter (N/A)
- [ ] Domain model struct for `requirement_sources`
- [ ] Params struct(s) for TASK-file and OpenSpec-backed requirement sources
- [ ] Params conversion functions from requirement sources to numbered requirements
- [ ] Any adapters between Given/When/Then spec deltas and the existing coverage matrix

## Files to Create/Modify

| File | Action |
|------|--------|
| `claude/agents/scribe.md` | Modify |
| `claude/skills/task-workflow/SKILL.md` | Modify |
| `claude/hooks/tests/test-openspec-routing.sh` | Modify |

## Requirements

**Functionality:**
- `scribe` accepts one `requirement_sources` contract backed either by a TASK file or by an OpenSpec artifact bundle
- Requirements extracted from either input shape map cleanly to implementation and tests
- Out-of-scope checks still work against the shared scope packet and declared non-goals
- Output remains compatible with the harness's existing review-trace parsing

**Key gotchas:**
- Do not make `design.md` the source of behavioral truth; it is supporting context, not the spec
- OpenSpec delta specs may express ADDED, MODIFIED, and REMOVED behavior; the requirement ledger must not silently drop one class

## Tests

Test cases:
- TASK-file requirement sources still work
- OpenSpec requirement sources yield a stable numbered requirement list
- Missing proposal/spec delta/design input fails loudly instead of auditing partial context
- Given/When/Then scenarios map into the existing coverage matrix

Verification commands:
- `bash claude/hooks/tests/test-openspec-routing.sh`
- `rg -n "requirement_sources|task_file|proposal.md|specs/|design.md" claude/agents/scribe.md claude/skills/task-workflow/SKILL.md`

## Acceptance Criteria

- [ ] `scribe` can audit either accepted requirement source shape
- [ ] The coverage matrix and verdict format remain stable for the rest of the harness
- [ ] Missing OpenSpec requirement inputs fail closed rather than quietly under-auditing the diff
